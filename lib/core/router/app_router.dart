import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/downloads/presentation/pages/downloads_page.dart';
import '../../features/playlists/presentation/pages/playlist_detail_page.dart';
import '../../features/playlists/presentation/pages/playlists_page.dart';
import '../../features/recitations/presentation/pages/home_page.dart';
import '../../features/recitations/presentation/pages/landing_page.dart';
import '../../features/recitations/presentation/pages/player_page.dart';

/// Route name constants.
abstract class AppRoutes {
  AppRoutes._();

  static const String landing = '/';
  static const String recitations = '/recitations/:collectionId';
  static const String downloads = '/downloads';
  static const String playlists = '/playlists';
  static const String playlistDetail = '/playlists/:playlistId';
  static const String player = '/player';
}

/// Application router built with [GoRouter].
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.landing,
    debugLogDiagnostics: true,
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
        builder: (context, state) => const DownloadsPage(),
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
        builder: (context, state) {
          // The recitation ID is passed as an extra parameter.
          final recitationId = state.extra as String?;
          return PlayerPage(initialRecitationId: recitationId);
        },
      ),
    ],
    errorBuilder: (context, state) => _RouterErrorPage(error: state.error),
  );
}

/// Fallback page shown when a route cannot be resolved.
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
