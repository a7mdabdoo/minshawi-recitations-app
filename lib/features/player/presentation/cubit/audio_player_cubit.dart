import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/battery_optimization_service.dart';
import '../../../recitations/data/datasources/local_recitation_data_source.dart';
import '../../../recitations/domain/entities/recitation.dart';
import '../../../recitations/presentation/cubit/download_cubit.dart';
import 'audio_player_state.dart';

class AudioPlayerCubit extends Cubit<AudioPlayerState> {
  final AudioPlayer _player;
  final LocalRecitationDataSource _localDataSource;

  final void Function(String recitationId, int positionSeconds)?
      onPositionSaved;
  final void Function(String recitationId)? onTrackPlayed;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  Recitation? _currentRecitation;
  Recitation? get currentRecitation => _currentRecitation;

  List<Recitation> _playlist = [];
  List<Recitation> get playlist => List.unmodifiable(_playlist);

  LoopMode _loopMode = LoopMode.off;
  LoopMode get loopMode => _loopMode;

  bool _isShuffleEnabled = false;
  bool get isShuffleEnabled => _isShuffleEnabled;

  double _speed = 1.0;
  double get speed => _speed;

  Duration? _abPointA;
  Duration? get abPointA => _abPointA;

  Duration? _abPointB;
  Duration? get abPointB => _abPointB;

  AbLoopState get abLoopState {
    if (_abPointA != null && _abPointB != null) return AbLoopState.active;
    if (_abPointA != null) return AbLoopState.pointASet;
    return AbLoopState.off;
  }

  int? _abRepeatCount;
  int? get abRepeatCount => _abRepeatCount;
  int _abRemainingRepeats = 0;
  int get abRemainingRepeats => _abRemainingRepeats;

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

  bool _isTransitioning = false;

  Timer? _networkTimeoutTimer;

  Duration _duration = Duration.zero;

  static Uri? _cachedArtworkUri;

  static Future<Uri?> _resolveArtworkUri() async {
    if (_cachedArtworkUri != null) return _cachedArtworkUri;
    try {
      _cachedArtworkUri =
          Uri.parse('asset:///assets/images/minshawi_portrait.jpg');
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

  void saveCurrentPosition() {
    final recitation = _currentRecitation;
    if (recitation != null) {
      final pos = _player.position.inSeconds;
      onPositionSaved?.call(recitation.id, pos);
      onTrackPlayed?.call(recitation.id);
    }
  }

  int? _lastSavedPositionSecond;

  void _bindStreams() {
    _durationSub = _player.durationStream.listen((realDuration) {
      if (realDuration != null && realDuration > Duration.zero) {
        _duration = realDuration;
        final s = state;
        if (s is AudioPlayerReady) {
          emit(s.copyWith(duration: realDuration));
        }
      }
    });

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
        final diff = (position - s.position).inMilliseconds.abs();
        if (diff >= 200 || position == Duration.zero) {
          emit(s.copyWith(position: position, isBuffering: false));
        }
      }

      final recitation = _currentRecitation;
      if (recitation != null &&
          position.inSeconds > 3 &&
          position.inSeconds % 5 == 0 &&
          _lastSavedPositionSecond != position.inSeconds) {
        _lastSavedPositionSecond = position.inSeconds;
        onPositionSaved?.call(recitation.id, position.inSeconds);
      }
    });

    _playerStateSub = _player.playerStateStream.listen((playerState) async {
      final processingState = playerState.processingState;
      final isPlaying = playerState.playing;
      final recitation = _currentRecitation;

      if (recitation == null) return;

      if (processingState == ProcessingState.completed) {
        if (_isTransitioning) return;
        _isTransitioning = true;

        if (_loopMode == LoopMode.one) {
          try {
            await _player.seek(Duration.zero);
            _isTransitioning = false;
            unawaited(_player.play().catchError((_) {}));
          } catch (_) {
            _isTransitioning = false;
          }
        } else if (_loopMode == LoopMode.all || _isShuffleEnabled) {
          await playNext();
        } else {
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
    debugPrint(
        '[AUDIO_PLAYBACK_ERROR] Recitation: ${recitation.id} (${recitation.surahNameAr}), Error: $error');
    _isTransitioning = false;
    _cancelNetworkTimeout();

    if (!kIsWeb) {
      final hivePath = _localDataSource.getDownloadedPath(recitation.id);
      if (hivePath != null && File(hivePath).existsSync()) {
        emit(AudioPlayerError(
          message: _mapErrorMessage(error),
          recitation: recitation,
        ));
        return;
      }
    }

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

  void updatePlaylist(List<Recitation> recitations) {
    if (recitations.isNotEmpty) {
      _playlist = List.from(recitations);
    }
  }

  Future<void> play(
    Recitation recitation, {
    List<Recitation>? playlist,
    Duration? initialPosition,
  }) async {
    _cancelNetworkTimeout();
    _lastSavedPositionSecond = null;

    if (playlist != null && playlist.isNotEmpty) {
      _playlist = List.from(playlist);
    }

    if (_currentRecitation?.id == recitation.id && state is AudioPlayerReady) {
      final readyState = state as AudioPlayerReady;
      if (initialPosition != null) {
        await _player.seek(initialPosition);
      }
      final isCurrentlyPlaying = readyState.isPlaying || _player.playing;
      if (isCurrentlyPlaying) {
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

    final startSeconds = initialPosition?.inSeconds ?? 0;
    onPositionSaved?.call(recitation.id, startSeconds);
    onTrackPlayed?.call(recitation.id);

    try {
      await _player.stop();

      String? validHivePath;
      final isCurrentlyDownloading = sl.isRegistered<DownloadCubit>() &&
          sl<DownloadCubit>().state.isDownloading(recitation.id);

      if (!kIsWeb && !isCurrentlyDownloading) {
        final hivePath = recitation.localFilePath ??
            _localDataSource.getDownloadedPath(recitation.id);

        if (hivePath != null) {
          final file = File(hivePath);
          if (await file.exists() && (await file.length()) > 0) {
            try {
              final testAccess = await file.open(mode: FileMode.read);
              await testAccess.close();
              validHivePath = hivePath;
            } catch (_) {
              validHivePath = null;
            }
          } else {
            await _localDataSource.removeDownloadedPath(recitation.id);
          }
        }
      }

      final albumName = switch (recitation.collectionId) {
        'mojawad' => 'المصحف المجود',
        'complete_murattal' => 'المصحف المرتل',
        'nahawand' => 'روائع النهاوند',
        'radio' => 'إذاعة القرآن الكريم',
        _ => 'التلاوات النادرة - تسجيلات ١٣٨٧ هـ',
      };

      final artUri = _cachedArtworkUri ?? await _resolveArtworkUri();

      final mediaTitle = recitation.collectionId == 'radio'
          ? recitation.surahNameAr
          : 'سورة ${recitation.surahNameAr}';

      final mediaItem = MediaItem(
        id: recitation.id,
        album: albumName,
        title: mediaTitle,
        artist: AppConstants.sheikhNameAr,
        artUri: artUri,
        duration: recitation.durationSeconds > 0
            ? Duration(seconds: recitation.durationSeconds)
            : null,
      );

      final AudioSource source = validHivePath != null
          ? AudioSource.file(
              validHivePath,
              tag: mediaItem,
            )
          : AudioSource.uri(
              Uri.parse(recitation.audioUrl),
              tag: mediaItem,
            );

      await _player.setAudioSource(
        source,
        initialPosition: initialPosition,
        preload: true,
      );
      await _player
          .setLoopMode(_loopMode == LoopMode.one ? LoopMode.one : LoopMode.off);
      _isTransitioning = false;
      unawaited(BatteryOptimizationService.acquireLocks());
      unawaited(_player.play().catchError((Object e) {
        _handlePlaybackError(e, recitation);
      }));
    } on PlayerException catch (e) {
      _handlePlaybackError(e, recitation);
    } catch (e) {
      _handlePlaybackError(e, recitation);
    }
  }

  Future<void> playNext() async {
    if (_playlist.isEmpty) {
      _isTransitioning = false;
      return;
    }

    if (_isShuffleEnabled && _playlist.length > 1) {
      final currentIdx =
          _playlist.indexWhere((r) => r.id == _currentRecitation?.id);
      int randomIdx;
      int attempts = 0;
      do {
        randomIdx = Random().nextInt(_playlist.length);
        attempts++;
      } while (randomIdx == currentIdx && attempts < 10);
      await play(_playlist[randomIdx]);
      return;
    }

    int currentIdx =
        _playlist.indexWhere((r) => r.id == _currentRecitation?.id);
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

  Future<void> playPrevious() async {
    if (_player.position.inSeconds > 3) {
      await seekTo(Duration.zero);
      return;
    }

    if (_playlist.isEmpty) return;

    int currentIdx =
        _playlist.indexWhere((r) => r.id == _currentRecitation?.id);
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

  void toggleLoopMode() {
    final nextMode = switch (_loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    _loopMode = nextMode;

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

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;

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

  Future<void> pause() async {
    saveCurrentPosition();
    unawaited(BatteryOptimizationService.releaseLocks());
    final s = state;
    if (s is AudioPlayerReady) {
      emit(s.copyWith(isPlaying: false, isBuffering: false));
    }
    try {
      await _player.pause();
    } catch (_) {}
  }

  Future<void> resume() async {
    unawaited(BatteryOptimizationService.acquireLocks());
    final s = state;
    if (s is AudioPlayerReady) {
      emit(s.copyWith(isPlaying: true, isBuffering: false));
    }
    try {
      unawaited(_player.play().catchError((Object e) {
        final rec = _currentRecitation;
        if (rec != null) {
          _handlePlaybackError(e, rec);
        }
      }));
    } catch (e) {
      final rec = _currentRecitation;
      if (rec != null) {
        _handlePlaybackError(e, rec);
      }
    }
  }

  Future<void> togglePlayPause() async {
    final s = state;
    final isCurrentlyPlaying =
        (s is AudioPlayerReady && s.isPlaying) || _player.playing;
    if (isCurrentlyPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> skipForward() async {
    final current = _player.position;
    final maxDuration = _player.duration ?? _duration;
    final target = current + const Duration(seconds: 10);
    final clamped = target > maxDuration ? maxDuration : target;
    await seekTo(clamped);
  }

  Future<void> skipBackward() async {
    final current = _player.position;
    final target = current - const Duration(seconds: 10);
    final clamped = target < Duration.zero ? Duration.zero : target;
    await seekTo(clamped);
  }

  Future<void> seekTo(Duration position) async {
    _lastSavedPositionSecond = null;
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

  Future<void> stop() async {
    _cancelNetworkTimeout();
    _lastSavedPositionSecond = null;
    saveCurrentPosition();
    _currentRecitation = null;
    _abPointA = null;
    _abPointB = null;
    await _player.stop();
    unawaited(BatteryOptimizationService.releaseLocks());
    emit(const AudioPlayerIdle());
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _player.setSpeed(speed);
    final s = state;
    if (s is AudioPlayerReady) {
      emit(s.copyWith(speed: _speed));
    }
  }

  double get volume => _player.volume;

  Future<void> setVolume(double val) async {
    await _player.setVolume(val.clamp(0.0, 1.0));
  }

  Future<void> togglePlaybackSpeed() async {
    final nextSpeed = switch (_speed) {
      1.0 => 1.25,
      1.25 => 1.5,
      1.5 => 0.75,
      _ => 1.0,
    };
    await setSpeed(nextSpeed);
  }

  Future<AbLoopState> cycleAbRepeat() async {
    if (_abPointA == null) {
      _abPointA = _player.position;
      _abPointB = null;
    } else if (_abPointB == null) {
      final currentPos = _player.position;
      if (currentPos > _abPointA!) {
        _abPointB = currentPos;
      } else {
        _abPointB = _abPointA;
        _abPointA = currentPos;
      }

      await _player.seek(_abPointA!);
    } else {
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

  void clearAbRepeat() {
    _abPointA = null;
    _abPointB = null;
    _abRemainingRepeats = _abRepeatCount ?? 0;
    final s = state;
    if (s is AudioPlayerReady) {
      emit(s.copyWith(clearAbPoints: true));
    }
  }

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
    unawaited(BatteryOptimizationService.releaseLocks());
    await _player.dispose();
    return super.close();
  }
}
