import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/downloads/presentation/cubit/downloaded_recitations_cubit.dart';
import '../../features/favorites/presentation/cubit/favorites_cubit.dart';
import '../../features/playlists/presentation/cubit/playlists_cubit.dart';
import '../../features/player/presentation/cubit/audio_player_cubit.dart';
import '../../features/player/presentation/cubit/sleep_timer_cubit.dart';
import '../../features/recitations/data/datasources/local_recitation_data_source.dart';
import '../../features/recitations/data/datasources/manifest_data_source.dart';
import '../../features/recitations/data/repositories/recitation_repository_impl.dart';
import '../../features/recitations/domain/repositories/recitation_repository.dart';
import '../../features/recitations/presentation/cubit/download_cubit.dart';
import '../../features/recitations/presentation/cubit/nahawand_cubit.dart';
import '../../features/recitations/presentation/cubit/recitation_list_cubit.dart';
import '../constants/app_constants.dart';
import '../network/dio_client.dart';
import '../settings/settings_cubit.dart';
import '../services/download_service.dart';
import '../theme/theme_cubit.dart';

final GetIt sl = GetIt.instance;

void _registerSingletonSafe<T extends Object>(T instance,
    {String? instanceName}) {
  if (instanceName != null) {
    if (sl.isRegistered<T>(instanceName: instanceName)) {
      sl.unregister<T>(instanceName: instanceName);
    }
    sl.registerSingleton<T>(instance, instanceName: instanceName);
  } else {
    if (sl.isRegistered<T>()) {
      sl.unregister<T>();
    }
    sl.registerSingleton<T>(instance);
  }
}

void _registerLazySingletonSafe<T extends Object>(T Function() factoryFunc,
    {String? instanceName}) {
  if (instanceName != null) {
    if (sl.isRegistered<T>(instanceName: instanceName)) {
      sl.unregister<T>(instanceName: instanceName);
    }
    sl.registerLazySingleton<T>(factoryFunc, instanceName: instanceName);
  } else {
    if (sl.isRegistered<T>()) {
      sl.unregister<T>();
    }
    sl.registerLazySingleton<T>(factoryFunc);
  }
}

Future<Box<dynamic>> _openBoxSafely(String boxName) async {
  if (Hive.isBoxOpen(boxName)) {
    return Hive.box<dynamic>(boxName);
  }
  try {
    return await Hive.openBox<dynamic>(boxName)
        .timeout(const Duration(seconds: 3));
  } catch (e, st) {
    debugPrint('[SERVICE_LOCATOR] Failed to open box "$boxName": $e\n$st');
    try {
      await Hive.deleteBoxFromDisk(boxName).timeout(const Duration(seconds: 1));
      return await Hive.openBox<dynamic>(boxName)
          .timeout(const Duration(seconds: 2));
    } catch (e2) {
      debugPrint('[SERVICE_LOCATOR] Recovery failed for "$boxName": $e2');
      return await Hive.openBox<dynamic>('${boxName}_safe')
          .timeout(const Duration(seconds: 2));
    }
  }
}

Future<void> setupServiceLocator() async {
  try {
    final recitationsBox =
        await _openBoxSafely(AppConstants.recitationsBoxName);
    final downloadedFilesBox =
        await _openBoxSafely(AppConstants.downloadedFilesBoxName);
    final settingsBox = await _openBoxSafely(AppConstants.settingsBoxName);
    final favoritesBox = await _openBoxSafely(AppConstants.favoritesBoxName);
    final playlistsBox = await _openBoxSafely(AppConstants.playlistsBoxName);

    _registerSingletonSafe<Box<dynamic>>(recitationsBox,
        instanceName: AppConstants.recitationsBoxName);
    _registerSingletonSafe<Box<dynamic>>(downloadedFilesBox,
        instanceName: AppConstants.downloadedFilesBoxName);
    _registerSingletonSafe<Box<dynamic>>(settingsBox,
        instanceName: AppConstants.settingsBoxName);
    _registerSingletonSafe<Box<dynamic>>(favoritesBox,
        instanceName: AppConstants.favoritesBoxName);
    _registerSingletonSafe<Box<dynamic>>(playlistsBox,
        instanceName: AppConstants.playlistsBoxName);

    _registerLazySingletonSafe<Dio>(() => DioClient.instance);

    _registerSingletonSafe<ThemeCubit>(ThemeCubit());
    _registerSingletonSafe<SettingsCubit>(
      SettingsCubit(
        sl<Box<dynamic>>(instanceName: AppConstants.settingsBoxName),
      ),
    );
    _registerSingletonSafe<FavoritesCubit>(
      FavoritesCubit(
        sl<Box<dynamic>>(instanceName: AppConstants.favoritesBoxName),
      ),
    );

    _registerLazySingletonSafe<DownloadService>(
      () => DownloadService(
        dio: sl<Dio>(),
        localDataSource: LocalRecitationDataSource(
          sl<Box<dynamic>>(instanceName: AppConstants.downloadedFilesBoxName),
        ),
      ),
    );

    _registerLazySingletonSafe<ManifestDataSource>(
      () => const ManifestDataSource(),
    );
    _registerLazySingletonSafe<LocalRecitationDataSource>(
      () => LocalRecitationDataSource(
        sl<Box<dynamic>>(instanceName: AppConstants.downloadedFilesBoxName),
      ),
    );

    _registerLazySingletonSafe<RecitationRepository>(
      () => RecitationRepositoryImpl(
        manifestDataSource: sl<ManifestDataSource>(),
        localDataSource: sl<LocalRecitationDataSource>(),
      ),
    );

    _registerSingletonSafe<PlaylistsCubit>(
      PlaylistsCubit(
        sl<Box<dynamic>>(instanceName: AppConstants.playlistsBoxName),
        sl<RecitationRepository>(),
      ),
    );

    _registerLazySingletonSafe<RecitationListCubit>(
      () => RecitationListCubit(sl<RecitationRepository>()),
    );

    _registerLazySingletonSafe<NahawandCubit>(
      () => NahawandCubit(
        manifestDataSource: sl<ManifestDataSource>(),
        localDataSource: sl<LocalRecitationDataSource>(),
      ),
    );

    _registerLazySingletonSafe<DownloadCubit>(
      () => DownloadCubit(
        downloadService: sl<DownloadService>(),
        recitationListCubit: sl<RecitationListCubit>(),
        nahawandCubit: sl<NahawandCubit>(),
      ),
    );

    _registerLazySingletonSafe<DownloadedRecitationsCubit>(
      () => DownloadedRecitationsCubit(
        manifestDataSource: sl<ManifestDataSource>(),
        localDataSource: sl<LocalRecitationDataSource>(),
        downloadService: sl<DownloadService>(),
        recitationListCubit: sl<RecitationListCubit>(),
        nahawandCubit: sl<NahawandCubit>(),
        downloadCubit: sl<DownloadCubit>(),
      ),
    );

    _registerSingletonSafe<AudioPlayerCubit>(
      AudioPlayerCubit(
        LocalRecitationDataSource(
          sl<Box<dynamic>>(instanceName: AppConstants.downloadedFilesBoxName),
        ),
        onPositionSaved: (id, pos) => sl<SettingsCubit>()
            .saveLastPlayed(recitationId: id, positionSeconds: pos),
        onTrackPlayed: (id) =>
            sl<SettingsCubit>().saveLastPlayedRecitationId(id),
      ),
    );

    _registerSingletonSafe<SleepTimerCubit>(
      SleepTimerCubit(sl<AudioPlayerCubit>()),
    );
  } catch (e, st) {
    debugPrint('[SERVICE_LOCATOR FATAL] Error during setup: $e\n$st');
  } finally {
    ensureFallbackServiceLocator();
  }
}

void ensureFallbackServiceLocator() {
  if (!sl.isRegistered<Dio>()) {
    _registerLazySingletonSafe<Dio>(() => DioClient.instance);
  }

  if (!sl.isRegistered<ThemeCubit>()) {
    _registerSingletonSafe<ThemeCubit>(ThemeCubit());
  }

  if (!sl.isRegistered<ManifestDataSource>()) {
    _registerLazySingletonSafe<ManifestDataSource>(
      () => const ManifestDataSource(),
    );
  }

  if (!sl.isRegistered<Box<dynamic>>(
      instanceName: AppConstants.settingsBoxName)) {
    if (Hive.isBoxOpen(AppConstants.settingsBoxName)) {
      _registerSingletonSafe<Box<dynamic>>(
        Hive.box<dynamic>(AppConstants.settingsBoxName),
        instanceName: AppConstants.settingsBoxName,
      );
    }
  }

  if (!sl.isRegistered<SettingsCubit>()) {
    Box<dynamic>? box;
    try {
      if (sl.isRegistered<Box<dynamic>>(
          instanceName: AppConstants.settingsBoxName)) {
        box = sl<Box<dynamic>>(instanceName: AppConstants.settingsBoxName);
      }
    } catch (_) {}
    if (box != null) {
      _registerSingletonSafe<SettingsCubit>(SettingsCubit(box));
    }
  }

  if (!sl.isRegistered<LocalRecitationDataSource>()) {
    Box<dynamic>? box;
    try {
      if (sl.isRegistered<Box<dynamic>>(
          instanceName: AppConstants.downloadedFilesBoxName)) {
        box =
            sl<Box<dynamic>>(instanceName: AppConstants.downloadedFilesBoxName);
      }
    } catch (_) {}
    if (box != null) {
      _registerLazySingletonSafe<LocalRecitationDataSource>(
        () => LocalRecitationDataSource(box!),
      );
    }
  }

  if (!sl.isRegistered<RecitationRepository>()) {
    _registerLazySingletonSafe<RecitationRepository>(
      () => RecitationRepositoryImpl(
        manifestDataSource: sl.isRegistered<ManifestDataSource>()
            ? sl<ManifestDataSource>()
            : const ManifestDataSource(),
        localDataSource: sl.isRegistered<LocalRecitationDataSource>()
            ? sl<LocalRecitationDataSource>()
            : LocalRecitationDataSource(sl<Box<dynamic>>(
                instanceName: AppConstants.downloadedFilesBoxName)),
      ),
    );
  }

  if (!sl.isRegistered<FavoritesCubit>()) {
    try {
      final box = sl<Box<dynamic>>(instanceName: AppConstants.favoritesBoxName);
      _registerSingletonSafe<FavoritesCubit>(FavoritesCubit(box));
    } catch (_) {}
  }

  if (!sl.isRegistered<PlaylistsCubit>()) {
    try {
      final box = sl<Box<dynamic>>(instanceName: AppConstants.playlistsBoxName);
      _registerSingletonSafe<PlaylistsCubit>(PlaylistsCubit(box));
    } catch (_) {}
  }

  if (!sl.isRegistered<RecitationListCubit>()) {
    _registerLazySingletonSafe<RecitationListCubit>(
      () => RecitationListCubit(sl<RecitationRepository>()),
    );
  }

  if (!sl.isRegistered<NahawandCubit>()) {
    _registerLazySingletonSafe<NahawandCubit>(
      () => NahawandCubit(
        manifestDataSource: sl.isRegistered<ManifestDataSource>()
            ? sl<ManifestDataSource>()
            : const ManifestDataSource(),
        localDataSource: sl<LocalRecitationDataSource>(),
      ),
    );
  }

  if (!sl.isRegistered<DownloadService>()) {
    _registerLazySingletonSafe<DownloadService>(
      () => DownloadService(
        dio: sl<Dio>(),
        localDataSource: sl<LocalRecitationDataSource>(),
      ),
    );
  }

  if (!sl.isRegistered<DownloadCubit>()) {
    _registerLazySingletonSafe<DownloadCubit>(
      () => DownloadCubit(
        downloadService: sl<DownloadService>(),
        recitationListCubit: sl<RecitationListCubit>(),
        nahawandCubit: sl<NahawandCubit>(),
      ),
    );
  }

  if (!sl.isRegistered<DownloadedRecitationsCubit>()) {
    _registerLazySingletonSafe<DownloadedRecitationsCubit>(
      () => DownloadedRecitationsCubit(
        manifestDataSource: sl.isRegistered<ManifestDataSource>()
            ? sl<ManifestDataSource>()
            : const ManifestDataSource(),
        localDataSource: sl<LocalRecitationDataSource>(),
        downloadService: sl<DownloadService>(),
        recitationListCubit: sl<RecitationListCubit>(),
        nahawandCubit: sl<NahawandCubit>(),
        downloadCubit: sl<DownloadCubit>(),
      ),
    );
  }

  if (!sl.isRegistered<AudioPlayerCubit>()) {
    _registerSingletonSafe<AudioPlayerCubit>(
      AudioPlayerCubit(
        LocalRecitationDataSource(
          sl<Box<dynamic>>(instanceName: AppConstants.downloadedFilesBoxName),
        ),
      ),
    );
  }

  if (!sl.isRegistered<SleepTimerCubit>()) {
    _registerSingletonSafe<SleepTimerCubit>(
      SleepTimerCubit(sl<AudioPlayerCubit>()),
    );
  }
}
