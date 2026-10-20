import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_cubit.dart';

class DesktopNavigationRail extends StatelessWidget {
  final String currentPath;

  const DesktopNavigationRail({
    super.key,
    required this.currentPath,
  });

  void _safeNavigate(BuildContext context, String path) {
    if (currentPath == path) return;
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          left: BorderSide(color: border, width: 1.0),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 18),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: gold, width: 1.5),
              image: const DecorationImage(
                image: ResizeImage(
                  AssetImage('assets/images/minshawi_portrait.jpg'),
                  width: 84,
                  height: 84,
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: border, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _RailIconItem(
                  icon: Icons.home_rounded,
                  tooltip: 'الرئيسية',
                  route: '/',
                  currentPath: currentPath,
                  onTap: () => _safeNavigate(context, '/'),
                ),
                _RailIconItem(
                  icon: Icons.menu_book_rounded,
                  tooltip: 'المصحف المرتل',
                  route: '/recitations/complete_murattal',
                  currentPath: currentPath,
                  onTap: () => _safeNavigate(context, '/recitations/complete_murattal'),
                ),
                _RailIconItem(
                  icon: Icons.auto_stories_rounded,
                  tooltip: 'المصحف المجود',
                  route: '/recitations/mojawad',
                  currentPath: currentPath,
                  onTap: () => _safeNavigate(context, '/recitations/mojawad'),
                ),
                _RailIconItem(
                  icon: Icons.star_rounded,
                  tooltip: 'التلاوات النادرة',
                  route: '/recitations/rare_1387',
                  currentPath: currentPath,
                  onTap: () => _safeNavigate(context, '/recitations/rare_1387'),
                ),
                _RailIconItem(
                  icon: Icons.queue_music_rounded,
                  tooltip: 'روائع النهاوند',
                  route: '/recitations/nahawand',
                  currentPath: currentPath,
                  onTap: () => _safeNavigate(context, '/recitations/nahawand'),
                ),
                _RailIconItem(
                  icon: Icons.download_done_rounded,
                  tooltip: 'التلاوات المحملة',
                  route: '/downloads',
                  currentPath: currentPath,
                  onTap: () => _safeNavigate(context, '/downloads'),
                ),
                _RailIconItem(
                  icon: Icons.favorite_rounded,
                  tooltip: 'المفضلة',
                  route: '/favorites',
                  currentPath: currentPath,
                  onTap: () => _safeNavigate(context, '/favorites'),
                ),
                _RailIconItem(
                  icon: Icons.playlist_play_rounded,
                  tooltip: 'قوائم التشغيل',
                  route: '/playlists',
                  currentPath: currentPath,
                  onTap: () => _safeNavigate(context, '/playlists'),
                ),
              ],
            ),
          ),
          Divider(color: border, height: 1),
          IconButton(
            tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: gold,
              size: 20,
            ),
            onPressed: () {
              context.read<ThemeCubit>().toggle();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _RailIconItem extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final String route;
  final String currentPath;
  final VoidCallback onTap;

  const _RailIconItem({
    required this.icon,
    required this.tooltip,
    required this.route,
    required this.currentPath,
    required this.onTap,
  });

  @override
  State<_RailIconItem> createState() => _RailIconItemState();
}

class _RailIconItemState extends State<_RailIconItem> {
  bool _isHovered = false;

  bool get _isActive {
    if (widget.route == '/') {
      return widget.currentPath == '/';
    }
    return widget.currentPath.startsWith(widget.route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isActive = _isActive;

    return Tooltip(
      message: widget.tooltip,
      preferBelow: false,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? gold.withAlpha(isDark ? 36 : 28)
                  : (_isHovered
                      ? (isDark
                          ? Colors.white.withAlpha(12)
                          : Colors.black.withAlpha(8))
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? gold.withAlpha(isDark ? 90 : 70)
                    : Colors.transparent,
                width: 1.0,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 22,
              color: isActive
                  ? gold
                  : (_isHovered
                      ? (isDark ? Colors.white : Colors.black)
                      : textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
