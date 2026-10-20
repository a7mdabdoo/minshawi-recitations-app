import 'dart:async';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/foundation.dart';
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
import 'features/downloads/presentation/cubit/downloaded_recitations_cubit.dart';
import 'features/favorites/presentation/cubit/favorites_cubit.dart';
import 'features/playlists/presentation/cubit/playlists_cubit.dart';
import 'features/player/presentation/cubit/audio_player_cubit.dart';
import 'features/player/presentation/cubit/sleep_timer_cubit.dart';
import 'features/recitations/presentation/cubit/download_cubit.dart';
import 'features/recitations/presentation/cubit/nahawand_cubit.dart';
import 'features/recitations/presentation/cubit/recitation_list_cubit.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        debugPrint(
            '[FLUTTER ERROR] ${details.exceptionAsString()}\n${details.stack}');
      };

      final isMobilePlatform = !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);

      if (isMobilePlatform) {
        try {
          await JustAudioBackground.init(
            androidNotificationChannelId:
                'com.example.quran_recitation_app.channel.audio',
            androidNotificationChannelName: 'جامع تلاوات المنشاوي',
            androidNotificationOngoing: true,
            androidStopForegroundOnPause: true,
            androidNotificationIcon: 'mipmap/ic_launcher',
          ).timeout(const Duration(seconds: 3));
        } catch (e, st) {
          debugPrint('[INIT WARNING] JustAudioBackground.init: $e\n$st');
        }

        try {
          final session =
              await AudioSession.instance.timeout(const Duration(seconds: 2));
          await session
              .configure(const AudioSessionConfiguration.music())
              .timeout(const Duration(seconds: 2));
        } catch (e, st) {
          debugPrint('[INIT WARNING] AudioSession.configure: $e\n$st');
        }

        try {
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]).timeout(const Duration(seconds: 2));

          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarDividerColor: Colors.transparent,
            ),
          );

          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        } catch (e, st) {
          debugPrint('[INIT WARNING] SystemChrome: $e\n$st');
        }
      }

      try {
        await Hive.initFlutter('al_minshawi_data').timeout(const Duration(seconds: 15));
      } catch (e, st) {
        debugPrint('[INIT WARNING] Hive.initFlutter: $e\n$st');
      }

      try {
        await setupServiceLocator().timeout(const Duration(seconds: 15));
      } catch (e, st) {
        debugPrint('[INIT WARNING] setupServiceLocator: $e\n$st');
      } finally {
        ensureFallbackServiceLocator();
      }

      runApp(const AlMinshawIApp());
    },
    (error, stack) {
      debugPrint('[FATAL UNCAUGHT] $error\n$stack');
    },
  );
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
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
        BlocProvider<NahawandCubit>.value(value: sl<NahawandCubit>()),
        BlocProvider<DownloadCubit>.value(value: sl<DownloadCubit>()),
        BlocProvider<DownloadedRecitationsCubit>.value(
            value: sl<DownloadedRecitationsCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'جامع تلاوات المنشاوي',
            debugShowCheckedModeBanner: false,
            scrollBehavior: const AppScrollBehavior(),
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
