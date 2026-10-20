import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_cubit.dart';

class DesktopSidebar extends StatelessWidget {
  final String currentPath;

  const DesktopSidebar({
    super.key,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          left: BorderSide(color: border, width: 1.0),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: gold, width: 1.5),
                    image: const DecorationImage(
                      image:
                          AssetImage('assets/images/minshawi_portrait.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'تلاوات المنشاوي',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: gold,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'الشيخ محمد صديق المنشاوي',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
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
              ],
            ),
          ),
          Divider(color: border, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              children: [
                _buildSectionHeader('المصاحف والتلاوات', textSecondary),
                _SidebarItem(
                  icon: Icons.home_rounded,
                  title: 'الرئيسية',
                  route: '/',
                  currentPath: currentPath,
                  onTap: () => context.go('/'),
                ),
                _SidebarItem(
                  icon: Icons.menu_book_rounded,
                  title: 'المصحف المرتل',
                  badgeText: '١١٤',
                  route: '/recitations/complete_murattal',
                  currentPath: currentPath,
                  onTap: () => context.go('/recitations/complete_murattal'),
                ),
                _SidebarItem(
                  icon: Icons.auto_stories_rounded,
                  title: 'المصحف المجود',
                  badgeText: '١١٤',
                  route: '/recitations/mojawad',
                  currentPath: currentPath,
                  onTap: () => context.go('/recitations/mojawad'),
                ),
                _SidebarItem(
                  icon: Icons.star_rounded,
                  title: 'التلاوات النادرة',
                  badgeText: '٢٦',
                  route: '/recitations/rare_1387',
                  currentPath: currentPath,
                  onTap: () => context.go('/recitations/rare_1387'),
                ),
                _SidebarItem(
                  icon: Icons.queue_music_rounded,
                  title: 'روائع النهاوند',
                  badgeText: '٣٠٣',
                  route: '/recitations/nahawand',
                  currentPath: currentPath,
                  onTap: () => context.go('/recitations/nahawand'),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('مكتبتي الخاصة', textSecondary),
                _SidebarItem(
                  icon: Icons.download_done_rounded,
                  title: 'التلاوات المحملة',
                  route: '/downloads',
                  currentPath: currentPath,
                  onTap: () => context.go('/downloads'),
                ),
                _SidebarItem(
                  icon: Icons.favorite_rounded,
                  title: 'المفضلة',
                  route: '/favorites',
                  currentPath: currentPath,
                  onTap: () => context.go('/favorites'),
                ),
                _SidebarItem(
                  icon: Icons.playlist_play_rounded,
                  title: 'قوائم التشغيل',
                  route: '/playlists',
                  currentPath: currentPath,
                  onTap: () => context.go('/playlists'),
                ),
              ],
            ),
          ),
          Divider(color: border, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.devDedication,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'الإصدار v1.2.0 • ويندوز',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: gold.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color.withAlpha(190),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? badgeText;
  final String route;
  final String currentPath;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    this.badgeText,
    required this.route,
    required this.currentPath,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
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
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isActive = _isActive;

    final itemBg = isActive
        ? gold.withAlpha(isDark ? 36 : 28)
        : (_isHovered
            ? (isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(8))
            : Colors.transparent);

    final itemColor = isActive
        ? gold
        : (_isHovered ? textPrimary : textSecondary);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: itemBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? gold.withAlpha(isDark ? 90 : 70)
                  : Colors.transparent,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: itemColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: itemColor,
                  ),
                ),
              ),
              if (widget.badgeText != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? gold.withAlpha(isDark ? 70 : 45)
                        : (isDark
                            ? Colors.white.withAlpha(16)
                            : Colors.black.withAlpha(10)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.badgeText!,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: itemColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
