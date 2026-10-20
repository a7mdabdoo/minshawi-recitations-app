import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_cubit.dart';

class DesktopSidebar extends StatelessWidget {
  final String currentPath;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const DesktopSidebar({
    super.key,
    required this.currentPath,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (_) {}
  }

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
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final sidebarWidth = isCollapsed ? 76.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          left: BorderSide(color: border, width: 1.0),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCollapsed ? 8 : 14,
              16,
              isCollapsed ? 8 : 14,
              12,
            ),
            child: isCollapsed
                ? Column(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: gold, width: 1.5),
                          image: const DecorationImage(
                            image: ResizeImage(
                              AssetImage('assets/images/minshawi_portrait.jpg'),
                              width: 76,
                              height: 76,
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      IconButton(
                        tooltip: 'توسيع القائمة الجانبية',
                        icon: Icon(
                          Icons.menu_rounded,
                          color: gold,
                          size: 22,
                        ),
                        onPressed: onToggleCollapse,
                      ),
                      IconButton(
                        tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: gold,
                          size: 18,
                        ),
                        onPressed: () => context.read<ThemeCubit>().toggle(),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: gold, width: 1.5),
                          image: const DecorationImage(
                            image: ResizeImage(
                              AssetImage('assets/images/minshawi_portrait.jpg'),
                              width: 80,
                              height: 80,
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'تلاوات المنشاوي',
                              style: GoogleFonts.cairo(
                                fontSize: 14.5,
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
                                fontSize: 10.5,
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
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: gold,
                          size: 19,
                        ),
                        onPressed: () => context.read<ThemeCubit>().toggle(),
                      ),
                      IconButton(
                        tooltip: 'طي القائمة الجانبية',
                        icon: Icon(
                          Icons.menu_open_rounded,
                          color: gold,
                          size: 21,
                        ),
                        onPressed: onToggleCollapse,
                      ),
                    ],
                  ),
          ),
          Divider(color: border, height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 6 : 10,
                vertical: 8,
              ),
              children: [
                if (!isCollapsed)
                  _buildSectionHeader('المصاحف والتلاوات', textSecondary),
                _SidebarItem(
                  icon: Icons.home_rounded,
                  title: 'الرئيسية',
                  route: '/',
                  currentPath: currentPath,
                  isCollapsed: isCollapsed,
                  onTap: () => _safeNavigate(context, '/'),
                ),
                _SidebarItem(
                  icon: Icons.auto_stories_rounded,
                  title: 'المصحف المرتل',
                  badgeText: '١١٤',
                  route: '/recitations/complete_murattal',
                  currentPath: currentPath,
                  isCollapsed: isCollapsed,
                  onTap: () =>
                      _safeNavigate(context, '/recitations/complete_murattal'),
                ),
                _SidebarItem(
                  icon: Icons.menu_book_rounded,
                  title: 'المصحف المجود',
                  badgeText: '١١٤',
                  route: '/recitations/mojawad',
                  currentPath: currentPath,
                  isCollapsed: isCollapsed,
                  onTap: () => _safeNavigate(context, '/recitations/mojawad'),
                ),
                _SidebarItem(
                  icon: Icons.star_rounded,
                  title: 'التلاوات النادرة',
                  badgeText: '٢٦',
                  route: '/recitations/rare_1387',
                  currentPath: currentPath,
                  isCollapsed: isCollapsed,
                  onTap: () => _safeNavigate(context, '/recitations/rare_1387'),
                ),
                _SidebarItem(
                  icon: Icons.graphic_eq_rounded,
                  title: 'روائع النهاوند',
                  badgeText: '٣٠٣',
                  route: '/recitations/nahawand',
                  currentPath: currentPath,
                  isCollapsed: isCollapsed,
                  onTap: () => _safeNavigate(context, '/recitations/nahawand'),
                ),
                const SizedBox(height: 10),
                if (!isCollapsed)
                  _buildSectionHeader('مكتبتي الخاصة', textSecondary),
                _SidebarItem(
                  icon: Icons.download_done_rounded,
                  title: 'التلاوات المحملة',
                  route: '/downloads',
                  currentPath: currentPath,
                  isCollapsed: isCollapsed,
                  onTap: () => _safeNavigate(context, '/downloads'),
                ),
                _SidebarItem(
                  icon: Icons.favorite_rounded,
                  title: 'المفضلة',
                  route: '/favorites',
                  currentPath: currentPath,
                  isCollapsed: isCollapsed,
                  onTap: () => _safeNavigate(context, '/favorites'),
                ),
                _SidebarItem(
                  icon: Icons.playlist_play_rounded,
                  title: 'قوائم التشغيل',
                  route: '/playlists',
                  currentPath: currentPath,
                  isCollapsed: isCollapsed,
                  onTap: () => _safeNavigate(context, '/playlists'),
                ),
              ],
            ),
          ),
          Divider(color: border, height: 1),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 6 : 14,
              vertical: 10,
            ),
            child: isCollapsed
                ? Tooltip(
                    message:
                        'تطوير: ${AppConstants.devNameAr}\n${AppConstants.devDedication}\nالإصدار v1.2.0',
                    child: Center(
                      child: Icon(
                        Icons.verified_user_rounded,
                        size: 20,
                        color: gold.withAlpha(180),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'تطوير: ${AppConstants.devNameAr}',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialIconButton(
                            iconPath: _SvgIcons.facebook,
                            tooltip: 'فيسبوك',
                            onTap: () => _launchUrl(AppConstants.devFacebookUrl),
                          ),
                          const SizedBox(width: 6),
                          _SocialIconButton(
                            iconPath: _SvgIcons.linkedin,
                            tooltip: 'لينكد إن',
                            onTap: () => _launchUrl(AppConstants.devLinkedinUrl),
                          ),
                          const SizedBox(width: 6),
                          _SocialIconButton(
                            iconPath: _SvgIcons.github,
                            tooltip: 'جيت هب',
                            onTap: () => _launchUrl(AppConstants.devGithubUrl),
                          ),
                          const SizedBox(width: 6),
                          _SocialIconButton(
                            iconPath: _SvgIcons.email,
                            tooltip: 'البريد الإلكتروني',
                            onTap: () => _launchUrl(AppConstants.devEmail),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppConstants.devDedication,
                        style: GoogleFonts.cairo(
                          fontSize: 9.5,
                          color: textSecondary,
                          height: 1.25,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الإصدار v1.2.0 • ويندوز وويب',
                        style: GoogleFonts.cairo(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: gold.withAlpha(190),
                        ),
                        textAlign: TextAlign.center,
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
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color.withAlpha(200),
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
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    this.badgeText,
    required this.route,
    required this.currentPath,
    required this.isCollapsed,
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

    final itemWidget = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 2.5),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCollapsed ? 0 : 12,
            vertical: 9,
          ),
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
          child: widget.isCollapsed
              ? Center(
                  child: Icon(
                    widget.icon,
                    size: 21,
                    color: itemColor,
                  ),
                )
              : Row(
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
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w600,
                          color: itemColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.badgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isActive
                              ? gold.withAlpha(isDark ? 70 : 45)
                              : (isDark
                                  ? Colors.white.withAlpha(16)
                                  : Colors.black.withAlpha(10)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.badgeText!,
                          style: GoogleFonts.cairo(
                            fontSize: 10.5,
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

    if (widget.isCollapsed) {
      return Tooltip(
        message: widget.badgeText != null
            ? '${widget.title} (${widget.badgeText})'
            : widget.title,
        child: itemWidget,
      );
    }

    return itemWidget;
  }
}

class _SocialIconButton extends StatelessWidget {
  final String iconPath;
  final String tooltip;
  final VoidCallback onTap;

  const _SocialIconButton({
    required this.iconPath,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Tooltip(
            message: tooltip,
            child: SizedBox(
              width: 15,
              height: 15,
              child: SvgPicture.string(
                iconPath.replaceAll('#COLOR', '#${color.toARGB32().toRadixString(16).substring(2)}'),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

abstract class _SvgIcons {
  static const String facebook = '''
<svg viewBox="0 0 24 24">
  <path fill="#COLOR" d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
</svg>
''';

  static const String linkedin = '''
<svg viewBox="0 0 24 24">
  <path fill="#COLOR" d="M19 3a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h14m-.5 15.5v-5.3a3.26 3.26 0 0 0-3.26-3.26c-.85 0-1.84.52-2.28 1.3v-1.11h-2.79v8.37h2.79v-4.93c0-.77.62-1.4 1.39-1.4a1.4 1.4 0 0 1 1.4 1.4v4.93h2.75M6.46 10.9v7.6h2.8v-7.6h-2.8M7.86 6.3a1.63 1.63 0 0 0-1.63 1.63c0 .9.73 1.63 1.63 1.63.9 0 1.63-.73 1.63-1.63 0-.9-.73-1.63-1.63-1.63Z"/>
</svg>
''';

  static const String github = '''
<svg viewBox="0 0 24 24">
  <path fill="#COLOR" d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0 0 24 12c0-6.63-5.37-12-12-12z"/>
</svg>
''';

  static const String email = '''
<svg viewBox="0 0 24 24">
  <path fill="#COLOR" d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/>
</svg>
''';
}
