import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../constants/app_constants.dart';

/// Immutable settings snapshot persisted in Hive's `settings_box`.
class SettingsState extends Equatable {
  /// The ID of the last recitation that was played.
  /// `null` if the user has not played anything yet.
  final String? lastPlayedRecitationId;

  /// The position in seconds of the last played recitation.
  final int? lastPlayedPositionSeconds;

  const SettingsState({
    this.lastPlayedRecitationId,
    this.lastPlayedPositionSeconds,
  });

  SettingsState copyWith({
    String? lastPlayedRecitationId,
    int? lastPlayedPositionSeconds,
    bool clearLastPlayed = false,
  }) {
    return SettingsState(
      lastPlayedRecitationId: clearLastPlayed
          ? null
          : (lastPlayedRecitationId ?? this.lastPlayedRecitationId),
      lastPlayedPositionSeconds: clearLastPlayed
          ? null
          : (lastPlayedPositionSeconds ?? this.lastPlayedPositionSeconds),
    );
  }

  @override
  List<Object?> get props => [lastPlayedRecitationId, lastPlayedPositionSeconds];
}

/// Manages user preferences that are **not** already covered by [ThemeCubit],
/// currently:
///  - [lastPlayedRecitationId] & [lastPlayedPositionSeconds] – restored on next cold start.
///
/// All writes go directly to the open Hive `settings_box` so they survive
/// process restarts without any extra plumbing.
class SettingsCubit extends Cubit<SettingsState> {
  final Box<dynamic> _box;

  SettingsCubit(this._box) : super(_loadInitial(_box));

  static SettingsState _loadInitial(Box<dynamic> box) {
    try {
      final lastPlayed =
          box.get(AppConstants.lastPlayedRecitationIdKey) as String?;
      final lastPosition =
          box.get(AppConstants.lastPlayedPositionSecondsKey) as int?;
      return SettingsState(
        lastPlayedRecitationId: lastPlayed,
        lastPlayedPositionSeconds: lastPosition,
      );
    } catch (_) {
      return const SettingsState();
    }
  }

  /// Persists [recitationId] and optional [positionSeconds] as the last-played track.
  Future<void> saveLastPlayed({
    required String recitationId,
    int positionSeconds = 0,
  }) async {
    try {
      await _box.put(AppConstants.lastPlayedRecitationIdKey, recitationId);
      await _box.put(
          AppConstants.lastPlayedPositionSecondsKey, positionSeconds);
      emit(state.copyWith(
        lastPlayedRecitationId: recitationId,
        lastPlayedPositionSeconds: positionSeconds,
      ));
    } catch (_) {
      // Fail silently — preference is non-critical.
    }
  }

  /// Backwards-compatible helper to save recitation ID.
  Future<void> saveLastPlayedRecitationId(String recitationId) async {
    return saveLastPlayed(
      recitationId: recitationId,
      positionSeconds: state.lastPlayedPositionSeconds ?? 0,
    );
  }

  /// Clears the stored last-played state (e.g. on data-reset or when finished).
  Future<void> clearLastPlayed() async {
    try {
      await _box.delete(AppConstants.lastPlayedRecitationIdKey);
      await _box.delete(AppConstants.lastPlayedPositionSecondsKey);
      emit(state.copyWith(clearLastPlayed: true));
    } catch (_) {}
  }

  /// Clears the stored last-played ID.
  Future<void> clearLastPlayedRecitationId() => clearLastPlayed();
}
