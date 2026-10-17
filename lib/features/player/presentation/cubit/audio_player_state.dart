import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import '../../../recitations/domain/entities/recitation.dart';

abstract class AudioPlayerState extends Equatable {
  const AudioPlayerState();

  @override
  List<Object?> get props => [];
}

class AudioPlayerIdle extends AudioPlayerState {
  const AudioPlayerIdle();
}

class AudioPlayerLoading extends AudioPlayerState {
  final Recitation recitation;
  const AudioPlayerLoading(this.recitation);

  @override
  List<Object?> get props => [recitation];
}

enum AbLoopState {
  off,

  pointASet,

  active,
}

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
  final int? abRepeatCount;

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
      abRepeatCount:
          clearAbRepeatCount ? null : (abRepeatCount ?? this.abRepeatCount),
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

class AudioPlayerError extends AudioPlayerState {
  final String message;
  final Recitation? recitation;

  const AudioPlayerError({required this.message, this.recitation});

  @override
  List<Object?> get props => [message, recitation];
}

extension AudioPlayerStateX on AudioPlayerState {
  Recitation? get currentRecitation {
    final s = this;
    if (s is AudioPlayerReady) return s.recitation;
    if (s is AudioPlayerLoading) return s.recitation;
    if (s is AudioPlayerError) return s.recitation;
    return null;
  }
}
