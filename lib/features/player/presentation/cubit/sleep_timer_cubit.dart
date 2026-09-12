import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'audio_player_cubit.dart';
import 'audio_player_state.dart';
import 'sleep_timer_state.dart';

class SleepTimerCubit extends Cubit<SleepTimerState> {
  final AudioPlayerCubit _audioPlayerCubit;
  Timer? _countdownTimer;
  StreamSubscription<AudioPlayerState>? _playerSub;
  String? _targetRecitationId;

  SleepTimerCubit(this._audioPlayerCubit) : super(SleepTimerState.initial);

  /// Starts a countdown timer for a specific [duration] with human-readable [label].
  void startTimer(Duration duration, String label) {
    cancelTimer();

    emit(SleepTimerState(
      mode: SleepTimerMode.duration,
      remainingTime: duration,
      totalDuration: duration,
      selectedOptionLabel: label,
    ));

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentRemaining = state.remainingTime ?? Duration.zero;
      if (currentRemaining <= const Duration(seconds: 1)) {
        _onTimerExpired();
      } else {
        emit(state.copyWith(
          remainingTime: currentRemaining - const Duration(seconds: 1),
        ));
      }
    });
  }

  /// Sets the timer to automatically pause at the end of the current playing surah.
  void setTimerEndOfSurah({String label = 'عند نهاية السورة'}) {
    cancelTimer();

    final playerState = _audioPlayerCubit.state;
    _targetRecitationId = playerState.currentRecitation?.id;

    emit(SleepTimerState(
      mode: SleepTimerMode.endOfSurah,
      selectedOptionLabel: label,
    ));

    _playerSub = _audioPlayerCubit.stream.listen((pState) {
      if (_targetRecitationId != null) {
        // If track changed or completed or player reset to idle
        if (pState.currentRecitation?.id != _targetRecitationId ||
            pState is AudioPlayerIdle) {
          _onTimerExpired();
        }
      }
    });
  }

  /// Cancels any active timer and resets state to inactive.
  void cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _playerSub?.cancel();
    _playerSub = null;
    _targetRecitationId = null;
    emit(SleepTimerState.initial);
  }

  void _onTimerExpired() {
    _audioPlayerCubit.pause();
    cancelTimer();
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _playerSub?.cancel();
    return super.close();
  }
}
