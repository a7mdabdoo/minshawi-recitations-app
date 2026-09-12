import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/favorites/presentation/cubit/favorites_cubit.dart';
import '../../features/playlists/presentation/cubit/playlists_cubit.dart';
import '../../features/player/presentation/cubit/audio_player_cubit.dart';
import '../../features/player/presentation/cubit/sleep_timer_cubit.dart';
import '../../features/recitations/data/datasources/local_recitation_data_source.dart';
import '../../features/recitations/data/datasources/manifest_data_source.dart';
import '../../features/recitations/data/repositories/recitation_repository_impl.dart';
import '../../features/recitations/domain/repositories/recitation_repository.dart';
import '../../features/recitations/presentation/cubit/download_cubit.dart';
import '../../features/recitations/presentation/cubit/recitation_list_cubit.dart';
import '../constants/app_constants.dart';
import '../network/dio_client.dart';
import '../settings/settings_cubit.dart';
import '../services/download_service.dart';
import '../theme/theme_cubit.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Initialises and registers all dependencies.
/// Must be called before [runApp].
Future<void> setupServiceLocator() async {

  final recitationsBox =
      await Hive.openBox<dynamic>(AppConstants.recitationsBoxName);
  final downloadedFilesBox =
      await Hive.openBox<dynamic>(AppConstants.downloadedFilesBoxName);
  final settingsBox =
      await Hive.openBox<dynamic>(AppConstants.settingsBoxName);
  final favoritesBox =
      await Hive.openBox<dynamic>(AppConstants.favoritesBoxName);
  final playlistsBox =
      await Hive.openBox<dynamic>(AppConstants.playlistsBoxName);

  // Register each box under its name so it can be retrieved by name later.
  sl.registerSingleton<Box<dynamic>>(recitationsBox,
      instanceName: AppConstants.recitationsBoxName);
  sl.registerSingleton<Box<dynamic>>(downloadedFilesBox,
      instanceName: AppConstants.downloadedFilesBoxName);
  sl.registerSingleton<Box<dynamic>>(settingsBox,
      instanceName: AppConstants.settingsBoxName);
  sl.registerSingleton<Box<dynamic>>(favoritesBox,
      instanceName: AppConstants.favoritesBoxName);
  sl.registerSingleton<Box<dynamic>>(playlistsBox,
      instanceName: AppConstants.playlistsBoxName);

  sl.registerLazySingleton<Dio>(() => DioClient.instance);

  sl.registerSingleton<ThemeCubit>(ThemeCubit());
  sl.registerSingleton<SettingsCubit>(
    SettingsCubit(
      sl<Box<dynamic>>(instanceName: AppConstants.settingsBoxName),
    ),
  );
  sl.registerSingleton<FavoritesCubit>(
    FavoritesCubit(
      sl<Box<dynamic>>(instanceName: AppConstants.favoritesBoxName),
    ),
  );
  
  sl.registerLazySingleton<DownloadService>(
    () => DownloadService(
      dio: sl<Dio>(),
      localDataSource: LocalRecitationDataSource(
        sl<Box<dynamic>>(instanceName: AppConstants.downloadedFilesBoxName),
      ),
    ),
  );



  // Data sources
  sl.registerLazySingleton<ManifestDataSource>(
    () => const ManifestDataSource(),
  );
  sl.registerLazySingleton<LocalRecitationDataSource>(
    () => LocalRecitationDataSource(
      sl<Box<dynamic>>(instanceName: AppConstants.downloadedFilesBoxName),
    ),
  );

  // Repository
  sl.registerLazySingleton<RecitationRepository>(
    () => RecitationRepositoryImpl(
      manifestDataSource: sl<ManifestDataSource>(),
      localDataSource: sl<LocalRecitationDataSource>(),
    ),
  );

  sl.registerSingleton<PlaylistsCubit>(
    PlaylistsCubit(
      sl<Box<dynamic>>(instanceName: AppConstants.playlistsBoxName),
      sl<RecitationRepository>(),
    ),
  );

  // RecitationListCubit — Singleton so DownloadCubit & HomePage share exact same state.
  sl.registerLazySingleton<RecitationListCubit>(
    () => RecitationListCubit(sl<RecitationRepository>()),
  );
  
  sl.registerLazySingleton<DownloadCubit>(
    () => DownloadCubit(
      downloadService: sl<DownloadService>(),
      recitationListCubit: sl<RecitationListCubit>(),
    ),
  );

  // Singleton — only one AudioPlayer instance should exist.
  sl.registerSingleton<AudioPlayerCubit>(
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

  // Sleep Timer Cubit
  sl.registerSingleton<SleepTimerCubit>(
    SleepTimerCubit(sl<AudioPlayerCubit>()),
  );
}
