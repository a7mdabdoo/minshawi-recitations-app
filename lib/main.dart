import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'core/constants/app_theme.dart';
import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/settings/settings_cubit.dart';
import 'core/theme/theme_cubit.dart';
import 'features/favorites/presentation/cubit/favorites_cubit.dart';
import 'features/playlists/presentation/cubit/playlists_cubit.dart';
import 'features/player/presentation/cubit/audio_player_cubit.dart';
import 'features/player/presentation/cubit/sleep_timer_cubit.dart';
import 'features/recitations/presentation/cubit/download_cubit.dart';
import 'features/recitations/presentation/cubit/recitation_list_cubit.dart';

Future<void> main() async {
  await runZonedGuarded(
    _bootstrap,
    (error, stack) {
      // Top-level error handler – log in production; rethrow in debug.
      debugPrint('[FATAL] $error\n$stack');
    },
  );
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background audio service for lockscreen and notification media controls
  await JustAudioBackground.init(
    androidNotificationChannelId:
        'com.example.quran_recitation_app.channel.audio',
    androidNotificationChannelName: 'جامع تلاوات المنشاوي',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
  );

  // Configure AudioSession to music mode to prevent OS from degrading audio quality
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await Hive.initFlutter();

  await setupServiceLocator();

  runApp(const AlMinshawIApp());
}

class AlMinshawIApp extends StatelessWidget {
  const AlMinshawIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: sl<ThemeCubit>()),
        BlocProvider<SettingsCubit>.value(value: sl<SettingsCubit>()),
        BlocProvider<FavoritesCubit>.value(value: sl<FavoritesCubit>()),
        BlocProvider<PlaylistsCubit>.value(value: sl<PlaylistsCubit>()),
        BlocProvider<AudioPlayerCubit>.value(value: sl<AudioPlayerCubit>()),
        BlocProvider<SleepTimerCubit>.value(value: sl<SleepTimerCubit>()),
        BlocProvider<RecitationListCubit>.value(
            value: sl<RecitationListCubit>()),
        BlocProvider<DownloadCubit>.value(value: sl<DownloadCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'جامع تلاوات المنشاوي',
            debugShowCheckedModeBanner: false,

            theme: AppTheme.lightTheme,

            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,

            routerConfig: AppRouter.router,

            locale: const Locale('ar', 'EG'),
            supportedLocales: const [
              Locale('ar', 'EG'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
