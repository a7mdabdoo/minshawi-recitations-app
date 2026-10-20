import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../desktop/desktop_app_shell.dart';
import '../../features/downloads/presentation/pages/downloads_page.dart';
import '../../features/playlists/presentation/pages/playlist_detail_page.dart';
import '../../features/playlists/presentation/pages/playlists_page.dart';
import '../../features/recitations/presentation/pages/home_page.dart';
import '../../features/recitations/presentation/pages/landing_page.dart';
import '../../features/recitations/presentation/pages/player_page.dart';

abstract class AppRoutes {
  AppRoutes._();

  static const String landing = '/';
  static const String recitations = '/recitations/:collectionId';
  static const String downloads = '/downloads';
  static const String favorites = '/favorites';
  static const String playlists = '/playlists';
  static const String playlistDetail = '/playlists/:playlistId';
  static const String player = '/player';
}

class AppRouter {
  AppRouter._();

  static String lastNonPlayerRoute = AppRoutes.landing;

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.landing,
    debugLogDiagnostics: true,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          if (state.matchedLocation != AppRoutes.player) {
            lastNonPlayerRoute = state.uri.toString();
          }
          return DesktopAppShell(
            currentPath: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.landing,
            name: 'landing',
            builder: (context, state) => const LandingPage(),
          ),
          GoRoute(
            path: AppRoutes.recitations,
            name: 'recitations',
            builder: (context, state) {
              final collectionId =
                  state.pathParameters['collectionId'] ?? 'rare_1387';
              return HomePage(collectionId: collectionId);
            },
          ),
          GoRoute(
            path: AppRoutes.downloads,
            name: 'downloads',
            builder: (context, state) {
              final collectionId = state.uri.queryParameters['collectionId'];
              return DownloadsPage(collectionId: collectionId);
            },
          ),
          GoRoute(
            path: AppRoutes.favorites,
            name: 'favorites',
            builder: (context, state) => const HomePage(
              collectionId: 'rare_1387',
              initialFavoritesTab: true,
            ),
          ),
          GoRoute(
            path: AppRoutes.playlists,
            name: 'playlists',
            builder: (context, state) => const PlaylistsPage(),
          ),
          GoRoute(
            path: AppRoutes.playlistDetail,
            name: 'playlistDetail',
            builder: (context, state) {
              final playlistId = state.pathParameters['playlistId'] ?? '';
              return PlaylistDetailPage(playlistId: playlistId);
            },
          ),
          GoRoute(
            path: AppRoutes.player,
            name: 'player',
            pageBuilder: (context, state) {
              final recitationId = state.extra as String?;
              return CustomTransitionPage<void>(
                key: state.pageKey,
                child: PlayerPage(initialRecitationId: recitationId),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOutCubic;
                  final tween =
                      Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _RouterErrorPage(error: state.error),
  );
}

class _RouterErrorPage extends StatelessWidget {
  final Exception? error;
  const _RouterErrorPage({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'الصفحة غير موجودة',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppRoutes.landing),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    );
  }
}
