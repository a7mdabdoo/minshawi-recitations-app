import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import '../../../recitations/domain/entities/recitation.dart';

/// All possible states of the audio engine.
abstract class AudioPlayerState extends Equatable {
  const AudioPlayerState();

  @override
  List<Object?> get props => [];
}

/// No track has been loaded yet.
class AudioPlayerIdle extends AudioPlayerState {
  const AudioPlayerIdle();
}

/// A new source URI is being resolved / buffered.
class AudioPlayerLoading extends AudioPlayerState {
  final Recitation recitation;
  const AudioPlayerLoading(this.recitation);

  @override
  List<Object?> get props => [recitation];
}

/// A-B Repeat loop state for memorization / focused listening.
enum AbLoopState {
  /// No A-B repeat active.
  off,

  /// Point A has been marked, awaiting Point B.
  pointASet,

  /// Both points A and B are active and looping.
  active,
}

/// Source is loaded and the player is ready (playing or paused).
class AudioPlayerReady extends AudioPlayerState {
  final Recitation recitation;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isBuffering;
  final LoopMode loopMode;
  final bool isShuffleEnabled;
  final double speed;
  final Duration? abPointA;
  final Duration? abPointB;
  final int? abRepeatCount; // null means infinite (∞)

  const AudioPlayerReady({
    required this.recitation,
    required this.position,
    required this.duration,
    required this.isPlaying,
    this.isBuffering = false,
    this.loopMode = LoopMode.off,
    this.isShuffleEnabled = false,
    this.speed = 1.0,
    this.abPointA,
    this.abPointB,
    this.abRepeatCount,
  });

  AbLoopState get abLoopState {
    if (abPointA != null && abPointB != null) return AbLoopState.active;
    if (abPointA != null) return AbLoopState.pointASet;
    return AbLoopState.off;
  }

  bool get isAbLoopActive => abLoopState == AbLoopState.active;

  double get progress {
    if (duration.inMilliseconds == 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  AudioPlayerReady copyWith({
    Recitation? recitation,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isBuffering,
    LoopMode? loopMode,
    bool? isShuffleEnabled,
    double? speed,
    Duration? abPointA,
    Duration? abPointB,
    int? abRepeatCount,
    bool clearAbPoints = false,
    bool clearAbRepeatCount = false,
  }) {
    return AudioPlayerReady(
      recitation: recitation ?? this.recitation,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      loopMode: loopMode ?? this.loopMode,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      speed: speed ?? this.speed,
      abPointA: clearAbPoints ? null : (abPointA ?? this.abPointA),
      abPointB: clearAbPoints ? null : (abPointB ?? this.abPointB),
      abRepeatCount: clearAbRepeatCount
          ? null
          : (abRepeatCount ?? this.abRepeatCount),
    );
  }

  @override
  List<Object?> get props => [
        recitation,
        position,
        duration,
        isPlaying,
        isBuffering,
        loopMode,
        isShuffleEnabled,
        speed,
        abPointA,
        abPointB,
        abRepeatCount,
      ];
}

/// A playback or source-load error occurred.
class AudioPlayerError extends AudioPlayerState {
  final String message;
  final Recitation? recitation;

  const AudioPlayerError({required this.message, this.recitation});

  @override
  List<Object?> get props => [message, recitation];
}

/// Convenience extension for reading the active recitation across states.
extension AudioPlayerStateX on AudioPlayerState {
  Recitation? get currentRecitation {
    final s = this;
    if (s is AudioPlayerReady) return s.recitation;
    if (s is AudioPlayerLoading) return s.recitation;
    if (s is AudioPlayerError) return s.recitation;
    return null;
  }
}
