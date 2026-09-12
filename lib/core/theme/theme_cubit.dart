import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

/// Manages the app-wide theme mode (dark / light).
class ThemeCubit extends Cubit<ThemeMode> {
  static const _key = AppConstants.themeKey;

  ThemeCubit() : super(_loadInitialTheme());

  static ThemeMode _loadInitialTheme() {
    try {
      final box = Hive.box<dynamic>(AppConstants.settingsBoxName);
      final stored = box.get(_key) as String?;
      return _fromString(stored);
    } catch (_) {
      return ThemeMode.dark;
    }
  }

  static ThemeMode _fromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  static String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  /// Toggle between dark and light.
  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _persist(next);
    emit(next);
  }

  /// Explicitly set a [ThemeMode].
  Future<void> setTheme(ThemeMode mode) async {
    await _persist(mode);
    emit(mode);
  }

  Future<void> _persist(ThemeMode mode) async {
    try {
      final box = Hive.box<dynamic>(AppConstants.settingsBoxName);
      await box.put(_key, _toString(mode));
    } catch (_) {
      // Fail silently – theme preference is non-critical.
    }
  }
}
