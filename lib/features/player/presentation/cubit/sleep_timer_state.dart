import 'package:equatable/equatable.dart';

enum SleepTimerMode {
  inactive,
  duration,
  endOfSurah,
}

class SleepTimerState extends Equatable {
  final SleepTimerMode mode;
  final Duration? remainingTime;
  final Duration? totalDuration;
  final String? selectedOptionLabel;

  const SleepTimerState({
    this.mode = SleepTimerMode.inactive,
    this.remainingTime,
    this.totalDuration,
    this.selectedOptionLabel,
  });

  bool get isActive => mode != SleepTimerMode.inactive;
  bool get isEndOfSurah => mode == SleepTimerMode.endOfSurah;

  SleepTimerState copyWith({
    SleepTimerMode? mode,
    Duration? remainingTime,
    Duration? totalDuration,
    String? selectedOptionLabel,
  }) {
    return SleepTimerState(
      mode: mode ?? this.mode,
      remainingTime: remainingTime ?? this.remainingTime,
      totalDuration: totalDuration ?? this.totalDuration,
      selectedOptionLabel: selectedOptionLabel ?? this.selectedOptionLabel,
    );
  }

  static const SleepTimerState initial = SleepTimerState();

  @override
  List<Object?> get props => [
        mode,
        remainingTime,
        totalDuration,
        selectedOptionLabel,
      ];
}
