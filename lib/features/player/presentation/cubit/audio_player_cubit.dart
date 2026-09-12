import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../recitations/data/datasources/local_recitation_data_source.dart';
import '../../../recitations/domain/entities/recitation.dart';
import 'audio_player_state.dart';

/// Cubit that owns the [AudioPlayer] instance and drives [AudioPlayerState].
///
/// Lifecycle & Features:
///  • [play]            – loads a new source and starts playback.
///  • [pause] / [resume]– toggles playback without reloading.
///  • [playNext]        – advances to next track in queue/shuffle.
///  • [playPrevious]    – moves to previous track.
///  • [toggleLoopMode]  – cycles Repeat Off -> Repeat All -> Repeat One.
///  • [toggleShuffle]   – enables/disables randomized playback.
///  • [seekTo]          – absolute seek.
///  • [skipForward]     – seek +10 s.
///  • [skipBackward]    – seek -10 s.
///  • [stop]            – stops and resets to [AudioPlayerIdle].
class AudioPlayerCubit extends Cubit<AudioPlayerState> {
  final AudioPlayer _player;
  final LocalRecitationDataSource _localDataSource;

  /// Optional hook called with the recitation ID and position in seconds.
  /// Used by [SettingsCubit] to persist the last-played position without a hard
  /// dependency between the player and settings layers.
  final void Function(String recitationId, int positionSeconds)? onPositionSaved;
  final void Function(String recitationId)? onTrackPlayed;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  /// The active recitation being played or loaded.
  Recitation? _currentRecitation;
  Recitation? get currentRecitation => _currentRecitation;

  /// The current playlist queue.
  List<Recitation> _playlist = [];

  /// Active Repeat mode (Off, All, One).
  LoopMode _loopMode = LoopMode.off;
  LoopMode get loopMode => _loopMode;

  /// Whether shuffle is active.
  bool _isShuffleEnabled = false;
  bool get isShuffleEnabled => _isShuffleEnabled;

  /// Playback speed (0.75x, 1.0x, 1.25x, 1.5x).
  double _speed = 1.0;
  double get speed => _speed;

  /// A-B Repeat Points
  Duration? _abPointA;
  Duration? get abPointA => _abPointA;

  Duration? _abPointB;
  Duration? get abPointB => _abPointB;

  AbLoopState get abLoopState {
    if (_abPointA != null && _abPointB != null) return AbLoopState.active;
    if (_abPointA != null) return AbLoopState.pointASet;
    return AbLoopState.off;
  }

  /// A-B Repeat repetition count (null = infinite ∞)
  int? _abRepeatCount;
  int? get abRepeatCount => _abRepeatCount;
  int _abRemainingRepeats = 0;
  int get abRemainingRepeats => _abRemainingRepeats;

  /// Sets repeat count for A-B loop (null = infinite ∞).
  void setAbRepeatCount(int? count) {
    _abRepeatCount = count;
    _abRemainingRepeats = count ?? 0;
    final s = state;
    if (s is AudioPlayerReady) {
      emit(s.copyWith(
        abRepeatCount: _abRepeatCount,
        clearAbRepeatCount: _abRepeatCount == null,
      ));
    }
  }

  /// Guard to prevent concurrent track transition triggers.
  bool _isTransitioning = false;

  /// Timer to allow a 7-second buffer delay before reporting network errors.
  Timer? _networkTimeoutTimer;

  /// The last known duration (updated via durationStream).
  Duration _duration = Duration.zero;

  /// Cached local file URI for the portrait artwork, bypassing flutter_cache_manager.
  static Uri? _cachedArtworkUri;

  /// Copies the portrait asset to local storage so audio_service / notification
  /// can read it directly via the file:// scheme without triggering flutter_cache_manager.
  static Future<Uri?> _resolveArtworkUri() async {
    if (_cachedArtworkUri != null) return _cachedArtworkUri;
    try {
      final docDir = await getApplicationSupportDirectory();
      final file = File('${docDir.path}/minshawi_art.jpg');
      if (!await file.exists()) {
        final byteData =
            await rootBundle.load('assets/images/minshawi_portrait.jpg');
        await file.writeAsBytes(
          byteData.buffer
              .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
          flush: true,
        );
      }
      _cachedArtworkUri = Uri.file(file.path);
      return _cachedArtworkUri;
    } catch (_) {
      return null;
    }
  }

  AudioPlayerCubit(
    this._localDataSource, {
    this.onPositionSaved,
    this.onTrackPlayed,
  })  : _player = AudioPlayer(
          audioLoadConfiguration: const AudioLoadConfiguration(
            androidLoadControl: AndroidLoadControl(
              minBufferDuration: Duration(seconds: 15),
              maxBufferDuration: Duration(seconds: 45),
              bufferForPlaybackDuration: Duration(seconds: 2),
              bufferForPlaybackAfterRebufferDuration: Duration(seconds: 4),
            ),
            darwinLoadControl: DarwinLoadControl(
              preferredForwardBufferDuration: Duration(seconds: 30),
            ),
          ),
        ),
        super(const AudioPlayerIdle()) {
    _bindStreams();
    unawaited(_resolveArtworkUri());
  }

  void _cancelNetworkTimeout() {
    _networkTimeoutTimer?.cancel();
    _networkTimeoutTimer = null;
  }

  /// Manually save current playback position to settings.
  void saveCurrentPosition() {
    final recitation = _currentRecitation;
    if (recitation != null) {
      final pos = _player.position.inSeconds;
      onPositionSaved?.call(recitation.id, pos);
      onTrackPlayed?.call(recitation.id);
    }
  }

  void _bindStreams() {
    // Duration: binds strictly to just_audio's native duration stream.
    _durationSub = _player.durationStream.listen((realDuration) {
      if (realDuration != null && realDuration > Duration.zero) {
        _duration = realDuration;
        final s = state;
        if (s is AudioPlayerReady) {
          emit(s.copyWith(duration: realDuration));
        }
      }
    });

    // Position: fires ~200 ms while playing.
    _positionSub = _player.positionStream.listen((position) {
      if (_abPointA != null && _abPointB != null && position >= _abPointB!) {
        if (_abRepeatCount != null && _abRepeatCount! > 0) {
          if (_abRemainingRepeats > 1) {
            _abRemainingRepeats--;
            _player.seek(_abPointA!);
          } else {
            clearAbRepeat();
          }
        } else {
          _player.seek(_abPointA!);
        }
        return;
      }

      final s = state;
      if (s is AudioPlayerReady) {
        emit(s.copyWith(position: position));
      }

      // Periodic persistence every 5s while playing
      final recitation = _currentRecitation;
      if (recitation != null &&
          position.inSeconds > 3 &&
          position.inSeconds % 5 == 0) {
        onPositionSaved?.call(recitation.id, position.inSeconds);
      }
    });

    // Player state: playing / paused / completed / buffering / ready.
    _playerStateSub = _player.playerStateStream.listen((playerState) async {
      final processingState = playerState.processingState;
      final isPlaying = playerState.playing;
      final recitation = _currentRecitation;

      if (recitation == null) return;

      if (processingState == ProcessingState.completed) {
        if (_isTransitioning) return;
        _isTransitioning = true;

        // Track finished — handle Repeat / Auto-play next.
        if (_loopMode == LoopMode.one) {
          try {
            await _player.seek(Duration.zero);
            await _player.play();
          } catch (_) {}
          _isTransitioning = false;
        } else if (_loopMode == LoopMode.all || _isShuffleEnabled) {
          await playNext();
        } else {
          // In repeat-off mode: auto advance if next track exists, else stop at end
          final idx = _playlist.indexWhere((r) => r.id == recitation.id);
          if (idx >= 0 && idx < _playlist.length - 1) {
            await playNext();
          } else {
            try {
              await _player.seek(Duration.zero);
              await _player.pause();
            } catch (_) {}
            _isTransitioning = false;
            final s = state;
            if (s is AudioPlayerReady) {
              emit(s.copyWith(
                position: Duration.zero,
                duration: _player.duration ?? _duration,
                isPlaying: false,
                isBuffering: false,
              ));
            } else {
              emit(AudioPlayerReady(
                recitation: recitation,
                position: Duration.zero,
                duration: _player.duration ?? _duration,
                isPlaying: false,
                isBuffering: false,
                loopMode: _loopMode,
                isShuffleEnabled: _isShuffleEnabled,
                speed: _speed,
                abPointA: _abPointA,
                abPointB: _abPointB,
              ));
            }
          }
        }
        return;
      }

      if (processingState == ProcessingState.ready) {
        _cancelNetworkTimeout();
        _isTransitioning = false;
        final s = state;
        if (s is AudioPlayerReady) {
          emit(s.copyWith(
            position: _player.position,
            duration: _player.duration ?? _duration,
            isPlaying: isPlaying,
            isBuffering: false,
            loopMode: _loopMode,
            isShuffleEnabled: _isShuffleEnabled,
            speed: _speed,
            abPointA: _abPointA,
            abPointB: _abPointB,
          ));
        } else {
          emit(AudioPlayerReady(
            recitation: recitation,
            position: _player.position,
            duration: _player.duration ?? _duration,
            isPlaying: isPlaying,
            isBuffering: false,
            loopMode: _loopMode,
            isShuffleEnabled: _isShuffleEnabled,
            speed: _speed,
            abPointA: _abPointA,
            abPointB: _abPointB,
          ));
        }
        return;
      }

      if (processingState == ProcessingState.buffering) {
        final s = state;
        if (s is AudioPlayerReady) {
          emit(s.copyWith(
            isPlaying: isPlaying,
            isBuffering: true,
          ));
        } else {
          emit(AudioPlayerReady(
            recitation: recitation,
            position: _player.position,
            duration: _player.duration ?? _duration,
            isPlaying: isPlaying,
            isBuffering: true,
            loopMode: _loopMode,
            isShuffleEnabled: _isShuffleEnabled,
            speed: _speed,
            abPointA: _abPointA,
            abPointB: _abPointB,
          ));
        }
        return;
      }

      if (processingState == ProcessingState.loading) {
        final s = state;
        if (s is AudioPlayerReady) {
          emit(s.copyWith(
            isPlaying: isPlaying,
            isBuffering: true,
          ));
        }
        return;
      }

      if (processingState == ProcessingState.idle) {
        if (state is! AudioPlayerError && state is! AudioPlayerLoading) {
          emit(const AudioPlayerIdle());
        }
      }
    }, onError: (Object e) {
      final recitation = _currentRecitation;
      if (recitation != null) {
        _handlePlaybackError(e, recitation);
      }
    });
  }

  void _handlePlaybackError(dynamic error, Recitation recitation) {
    _isTransitioning = false;
    _cancelNetworkTimeout();

    // Check if this was a local downloaded file
    final hivePath = _localDataSource.getDownloadedPath(recitation.id);
    if (hivePath != null && File(hivePath).existsSync()) {
      emit(AudioPlayerError(
        message: _mapErrorMessage(error),
        recitation: recitation,
      ));
      return;
    }

    // For network streams: give a 7-second buffer/loading grace period before showing error
    _networkTimeoutTimer = Timer(const Duration(seconds: 7), () {
      if (!isClosed &&
          (state is AudioPlayerLoading ||
              (state is AudioPlayerReady &&
                  (state as AudioPlayerReady).isBuffering))) {
        emit(AudioPlayerError(
          message: _mapErrorMessage(error),
          recitation: recitation,
        ));
      }
    });
  }

  String _mapErrorMessage(dynamic error) {
    final str = error.toString().toLowerCase();
    if (str.contains('socketexception') ||
        str.contains('failed host lookup') ||
        str.contains('network') ||
        str.contains('connection refused') ||
        str.contains('connection aborted') ||
        str.contains('connection reset') ||
        str.contains('httpexception') ||
        str.contains('handshakeexception') ||
        str.contains('timed out') ||
        str.contains('timeout') ||
        str.contains('type_source') ||
        str.contains('404') ||
        str.contains('500') ||
        str.contains('503') ||
        str.contains('invalidresponsecodeexception') ||
        str.contains('source error') ||
        str.contains('clientexception')) {
      return 'لا يتوفر اتصال بالإنترنت. يرجى الاتصال بالشبكة أو الاستماع للتلاوات المحمّلة';
    }
    if (error is PlayerException) {
      final msg = (error.message ?? '').toLowerCase();
      if (msg.contains('404') ||
          msg.contains('source') ||
          msg.contains('response code') ||
          msg.contains('network')) {
        return 'لا يتوفر اتصال بالإنترنت. يرجى الاتصال بالشبكة أو الاستماع للتلاوات المحمّلة';
      }
    }
    return 'تعذّر تشغيل الملف الصوتي. يرجى التحقق من الاتصال والمحاولة مجدداً';
  }

  /// Updates the playlist in memory so next/previous/shuffle navigation works.
  void updatePlaylist(List<Recitation> recitations) {
    if (recitations.isNotEmpty) {
      _playlist = List.from(recitations);
    }
  }

  /// Load [recitation] and start playing immediately, with optional [initialPosition].
  Future<void> play(
    Recitation recitation, {
    List<Recitation>? playlist,
    Duration? initialPosition,
  }) async {
    _cancelNetworkTimeout();

    if (playlist != null && playlist.isNotEmpty) {
      _playlist = List.from(playlist);
    }

    // If the same recitation is already loaded and ready, toggle play/pause smoothly
    if (_currentRecitation?.id == recitation.id && state is AudioPlayerReady) {
      final readyState = state as AudioPlayerReady;
      if (initialPosition != null) {
        await _player.seek(initialPosition);
      }
      if (readyState.isPlaying) {
        await pause();
      } else {
        await resume();
      }
      return;
    }

    _currentRecitation = recitation;
    _duration = _player.duration ??
        (recitation.durationSeconds > 0
            ? Duration(seconds: recitation.durationSeconds)
            : Duration.zero);
    emit(AudioPlayerLoading(recitation));

    // Persist last-played track and initial position
    final startSeconds = initialPosition?.inSeconds ?? 0;
    onPositionSaved?.call(recitation.id, startSeconds);
    onTrackPlayed?.call(recitation.id);

    try {
      // Stop previous playback
      await _player.stop();

      // Check Hive for a local file path
      String? validHivePath;
      final hivePath = _localDataSource.getDownloadedPath(recitation.id);

      if (hivePath != null) {
        final file = File(hivePath);
        if (await file.exists() && (await file.length()) > 0) {
          validHivePath = hivePath;
        } else {
          // File was deleted manually outside the app; clear the stale entry.
          await _localDataSource.removeDownloadedPath(recitation.id);
        }
      }

      final albumName = switch (recitation.collectionId) {
        'mojawad' => 'المصحف المجود',
        'complete_murattal' => 'المصحف المرتل كاملاً',
        _ => 'التلاوات النادرة - تسجيلات ١٣٨٧ هـ',
      };

      // Resolve portrait artwork to a file:// URI to avoid network downloading via cache manager
      final artUri = _cachedArtworkUri ?? await _resolveArtworkUri();

      final mediaItem = MediaItem(
        id: recitation.id,
        album: albumName,
        title: 'سورة ${recitation.surahNameAr}',
        artist: AppConstants.sheikhNameAr,
        artUri: artUri,
        duration: recitation.durationSeconds > 0
            ? Duration(seconds: recitation.durationSeconds)
            : null,
      );

      // Direct streaming from remote URL or local file without cache manager
      final AudioSource source = validHivePath != null
          ? AudioSource.uri(
              Uri.file(validHivePath),
              tag: mediaItem,
            )
          : AudioSource.uri(
              Uri.parse(recitation.audioUrl),
              tag: mediaItem,
              headers: const {
                'Accept': 'audio/mpeg, audio/*, */*',
              },
            );

      await _player.setAudioSource(
        source,
        initialPosition: initialPosition,
        preload: true,
      );
      await _player.setLoopMode(_loopMode == LoopMode.one ? LoopMode.one : LoopMode.off);
      await _player.play();
      _isTransitioning = false;
    } on PlayerException catch (e) {
      _handlePlaybackError(e, recitation);
    } catch (e) {
      _handlePlaybackError(e, recitation);
    }
  }

  /// Advances to the next recitation in queue / shuffle.
  Future<void> playNext() async {
    if (_playlist.isEmpty) {
      _isTransitioning = false;
      return;
    }

    if (_isShuffleEnabled && _playlist.length > 1) {
      final currentIdx = _playlist.indexWhere((r) => r.id == _currentRecitation?.id);
      int randomIdx;
      int attempts = 0;
      do {
        randomIdx = Random().nextInt(_playlist.length);
        attempts++;
      } while (randomIdx == currentIdx && attempts < 10);
      await play(_playlist[randomIdx]);
      return;
    }

    int currentIdx = _playlist.indexWhere((r) => r.id == _currentRecitation?.id);
    if (currentIdx == -1 && _playlist.isNotEmpty) {
      currentIdx = 0;
    }

    if (currentIdx >= 0 && currentIdx < _playlist.length - 1) {
      await play(_playlist[currentIdx + 1]);
    } else if (_loopMode == LoopMode.all) {
      await play(_playlist.first);
    } else {
      _isTransitioning = false;
    }
  }

  /// Moves to the previous recitation or restarts current track.
  Future<void> playPrevious() async {
    if (_player.position.inSeconds > 3) {
      await seekTo(Duration.zero);
      return;
    }

    if (_playlist.isEmpty) return;

    int currentIdx = _playlist.indexWhere((r) => r.id == _currentRecitation?.id);
    if (currentIdx == -1 && _playlist.isNotEmpty) {
      currentIdx = 0;
    }

    if (currentIdx > 0) {
      await play(_playlist[currentIdx - 1]);
    } else if (_loopMode == LoopMode.all) {
      await play(_playlist.last);
    } else {
      await seekTo(Duration.zero);
    }
  }

  /// Cycles repeat mode instantly: Off -> All -> One -> Off.
  /// Mutually exclusive with Shuffle mode: activating Repeat disables Shuffle.
  void toggleLoopMode() {
    final nextMode = switch (_loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    _loopMode = nextMode;

    // Mutually exclusive: if activating repeat (All or One), turn OFF shuffle
    if (_loopMode != LoopMode.off) {
      _isShuffleEnabled = false;
    }

    _player
        .setLoopMode(_loopMode == LoopMode.one ? LoopMode.one : LoopMode.off)
        .catchError((_) {});

    final s = state;
    if (s is AudioPlayerReady) {
      emit(s.copyWith(
        loopMode: _loopMode,
        isShuffleEnabled: _isShuffleEnabled,
      ));
    } else if (s is AudioPlayerLoading) {
      emit(AudioPlayerLoading(s.recitation));
    }
  }

  /// Toggles shuffle mode on/off instantly.
  /// Mutually exclusive with Repeat mode: enabling Shuffle disables Repeat.
  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;

    // Mutually exclusive: if turning Shuffle ON, turn OFF repeat
    if (_isShuffleEnabled) {
      _loopMode = LoopMode.off;
      _player.setLoopMode(LoopMode.off).catchError((_) {});
    }

    final s = state;
    if (s is AudioPlayerReady) {
      emit(s.copyWith(
        isShuffleEnabled: _isShuffleEnabled,
        loopMode: _loopMode,
      ));
    } else if (s is AudioPlayerLoading) {
      emit(AudioPlayerLoading(s.recitation));
    }
  }

  /// Pause current playback.
  Future<void> pause() async {
    saveCurrentPosition();
    await _player.pause();
    final s = state;
    if (s is AudioPlayerReady) {
      emit(s.copyWith(isPlaying: false));
    }
  }

  /// Resume playback.
  Future<void> resume() async {
    await _player.play();
    final s = state;
    if (s is AudioPlayerReady) {
      emit(s.copyWith(isPlaying: true));
    }
  }

  /// Toggle play/pause.
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Seek forward 10 seconds.
  Future<void> skipForward() async {
    final current = _player.position;
    final maxDuration = _player.duration ?? _duration;
    final target = current + const Duration(seconds: 10);
    final clamped = target > maxDuration ? maxDuration : target;
    await seekTo(clamped);
  }

  /// Seek backward 10 seconds.
  Future<void> skipBackward() async {
    final current = _player.position;
    final target = current - const Duration(seconds: 10);
    final clamped = target < Duration.zero ? Duration.zero : target;
    await seekTo(clamped);
  }

  /// Seek to [position].
  Future<void> seekTo(Duration position) async {
    final maxDuration = _player.duration ?? _duration;
    final clamped = position < Duration.zero
        ? Duration.zero
        : (position > maxDuration ? maxDuration : position);
    await _player.seek(clamped);
    saveCurrentPosition();
    final s = state;
    if (s is AudioPlayerReady) {
      emit(s.copyWith(position: clamped));
    }
  }

  /// Stop playback and return to [AudioPlayerIdle].
  Future<void> stop() async {
    _cancelNetworkTimeout();
    saveCurrentPosition();
    _currentRecitation = null;
    _abPointA = null;
    _abPointB = null;
    await _player.stop();
    emit(const AudioPlayerIdle());
  }

  /// Sets the playback speed without altering audio pitch (0.75x, 1.0x, 1.25x, 1.5x).
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _player.setSpeed(speed);
    final s = state;
    if (s is AudioPlayerReady) {
      emit(s.copyWith(speed: _speed));
    }
  }

  /// Current audio volume (0.0 to 1.0).
  double get volume => _player.volume;

  /// Sets audio player volume (0.0 to 1.0).
  Future<void> setVolume(double val) async {
    await _player.setVolume(val.clamp(0.0, 1.0));
  }

  /// Cycles playback speed: 1.0x -> 1.25x -> 1.5x -> 0.75x -> 1.0x.
  Future<void> togglePlaybackSpeed() async {
    final nextSpeed = switch (_speed) {
      1.0 => 1.25,
      1.25 => 1.5,
      1.5 => 0.75,
      _ => 1.0,
    };
    await setSpeed(nextSpeed);
  }

  /// Cycles through A-B repeat states:
  /// - State 0 (Off) -> Sets Point A
  /// - State 1 (Point A Set) -> Sets Point B & Starts loop
  /// - State 2 (Active Loop) -> Clears loop & resets
  Future<AbLoopState> cycleAbRepeat() async {
    if (_abPointA == null) {
      // Step 1: Set Point A at current playback position
      _abPointA = _player.position;
      _abPointB = null;
    } else if (_abPointB == null) {
      // Step 2: Set Point B and activate loop
      final currentPos = _player.position;
      if (currentPos > _abPointA!) {
        _abPointB = currentPos;
      } else {
        // Position is at or before Point A, adjust interval
        _abPointB = _abPointA;
        _abPointA = currentPos;
      }
      // Instantly start loop from Point A
      await _player.seek(_abPointA!);
    } else {
      // Step 3: Reset loop
      _abPointA = null;
      _abPointB = null;
    }

    final s = state;
    if (s is AudioPlayerReady) {
      emit(s.copyWith(
        abPointA: _abPointA,
        abPointB: _abPointB,
        clearAbPoints: _abPointA == null && _abPointB == null,
      ));
    }

    return abLoopState;
  }

  /// Clears any active A-B repeat points and disables loop.
  void clearAbRepeat() {
    _abPointA = null;
    _abPointB = null;
    _abRemainingRepeats = _abRepeatCount ?? 0;
    final s = state;
    if (s is AudioPlayerReady) {
      emit(s.copyWith(clearAbPoints: true));
    }
  }

  /// Sets Point A explicitly at the given duration or current playback position.
  void setPointA([Duration? pos]) {
    _abPointA = pos ?? _player.position;
    if (_abPointB != null && _abPointB! <= _abPointA!) {
      _abPointB = null;
    }
    final s = state;
    if (s is AudioPlayerReady) {
      emit(s.copyWith(
        abPointA: _abPointA,
        abPointB: _abPointB,
        clearAbPoints: _abPointB == null,
      ));
    }
  }

  /// Sets Point B explicitly at the given duration or current position and activates the loop.
  Future<void> setPointB([Duration? pos]) async {
    final currentPos = pos ?? _player.position;
    _abPointA ??= Duration.zero;
    if (currentPos > _abPointA!) {
      _abPointB = currentPos;
    } else {
      _abPointB = _abPointA;
      _abPointA = currentPos;
    }
    _abRemainingRepeats = _abRepeatCount ?? 0;
    await _player.seek(_abPointA!);
    final s = state;
    if (s is AudioPlayerReady) {
      emit(s.copyWith(
        abPointA: _abPointA,
        abPointB: _abPointB,
      ));
    }
  }

  @override
  Future<void> close() async {
    _cancelNetworkTimeout();
    await _playerStateSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _player.dispose();
    return super.close();
  }
}
