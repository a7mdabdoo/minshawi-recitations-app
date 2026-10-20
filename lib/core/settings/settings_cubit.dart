import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../constants/app_constants.dart';

class SettingsState extends Equatable {
  final String? lastPlayedRecitationId;

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
  List<Object?> get props =>
      [lastPlayedRecitationId, lastPlayedPositionSeconds];
}

class SettingsCubit extends Cubit<SettingsState> {
  final Box<dynamic>? _box;

  SettingsCubit([this._box]) : super(_loadInitial(_box));

  static SettingsState _loadInitial(Box<dynamic>? box) {
    if (box == null) return const SettingsState();
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

  Future<void> saveLastPlayed({
    required String recitationId,
    int positionSeconds = 0,
  }) async {
    try {
      await _box?.put(AppConstants.lastPlayedRecitationIdKey, recitationId);
      await _box?.put(
          AppConstants.lastPlayedPositionSecondsKey, positionSeconds);
      emit(state.copyWith(
        lastPlayedRecitationId: recitationId,
        lastPlayedPositionSeconds: positionSeconds,
      ));
    } catch (_) {}
  }

  Future<void> saveLastPlayedRecitationId(String recitationId) async {
    return saveLastPlayed(
      recitationId: recitationId,
      positionSeconds: state.lastPlayedPositionSeconds ?? 0,
    );
  }

  Future<void> clearLastPlayed() async {
    try {
      await _box?.delete(AppConstants.lastPlayedRecitationIdKey);
      await _box?.delete(AppConstants.lastPlayedPositionSecondsKey);
      emit(state.copyWith(clearLastPlayed: true));
    } catch (_) {}
  }

  Future<void> clearLastPlayedRecitationId() => clearLastPlayed();
}
