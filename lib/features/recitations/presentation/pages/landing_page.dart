import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../playlists/domain/entities/playlist.dart';
import '../../../playlists/presentation/cubit/playlists_cubit.dart';
import '../../../playlists/presentation/cubit/playlists_state.dart';
import '../../../playlists/presentation/pages/playlist_detail_page.dart';
import '../../../player/presentation/cubit/audio_player_cubit.dart';
import '../../../player/presentation/cubit/audio_player_state.dart';
import '../../../player/presentation/widgets/mini_player.dart';
import '../../../recitations/domain/entities/recitation.dart';
import '../../../recitations/presentation/cubit/recitation_list_cubit.dart';
import '../../../recitations/presentation/cubit/recitation_list_state.dart';

enum _LandingTab { collections, playlists }

class LandingPage extends StatefulWidget {
  final ui.Image? portraitUiImage;
  const LandingPage({super.key, this.portraitUiImage});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  _LandingTab _selectedTab = _LandingTab.collections;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final bg = isDark ? const Color(0xFF0F141C) : AppColors.lightBackground;

    return BlocListener<AudioPlayerCubit, AudioPlayerState>(
      listenWhen: (prev, curr) => curr is AudioPlayerError,
      listener: (context, state) {
        if (state is AudioPlayerError) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: AppColors.goldPrimary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.message,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                96.0 + MediaQuery.of(context).padding.bottom,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: AppColors.goldPrimary.withAlpha(160),
                  width: 1.2,
                ),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            10,
                            16,
                            96.0 + MediaQuery.of(context).padding.bottom,
                          ),
                          child: Column(
                            children: [
                              _UnifiedHeroBanner(
                                isDark: isDark,
                                gold: gold,
                                portraitUiImage: widget.portraitUiImage,
                              ),

                              const SizedBox(height: 14),

                              _LandingSegmentedTabs(
                                selectedTab: _selectedTab,
                                isDark: isDark,
                                onTabSelected: (tab) =>
                                    setState(() => _selectedTab = tab),
                              ),

                              if (_selectedTab == _LandingTab.collections) ...[
                                _VerticalCategoryCards(isDark: isDark),
                              ] else ...[
                                _LandingPlaylistsSection(
                                  isDark: isDark,
                                  gold: gold,
                                ),
                              ],

                              const Spacer(),
                              const SizedBox(height: 16),

                              _FramelessDeveloperFooter(isDark: isDark),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// قسم قوائم التشغيل المخصصة داخل الصفحة الرئيسية (خالي تماماً من أخطاء السكرول)
// ─────────────────────────────────────────────────────────
class _LandingPlaylistsSection extends StatelessWidget {
  final bool isDark;
  final Color gold;

  const _LandingPlaylistsSection({
    required this.isDark,
    required this.gold,
  });

  void _showCreateDialog(BuildContext context) {
    final cardBg =
    isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final textPrimary =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'إنشاء قائمة تشغيل جديدة',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'اسم القائمة (مثال: تلاوات مختارة)...',
              hintStyle: GoogleFonts.cairo(color: textSecondary, fontSize: 13),
              filled: true,
              fillColor: (isDark ? Colors.white : Colors.black).withAlpha(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: gold.withAlpha(isDark ? 80 : 50),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: gold, width: 1.5),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor:
                isDark ? AppColors.darkBackground : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(dialogCtx).pop();
                  await context.read<PlaylistsCubit>().createPlaylist(name);
                }
              },
              child: Text(
                'إنشاء',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(
      BuildContext context,
      String playlistId,
      String playlistTitle,
      ) {
    final cardBg =
    isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final textPrimary =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'حذف قائمة التشغيل؟',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          content: Text(
            'هل ترغب في حذف قائمة التشغيل "$playlistTitle" نهائياً؟',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkError,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await context.read<PlaylistsCubit>().deletePlaylist(playlistId);
              },
              child: Text(
                'حذف',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg =
    isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final textPrimary =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return BlocBuilder<PlaylistsCubit, PlaylistsState>(
      builder: (context, state) {
        final playlists = state is PlaylistsLoaded ? state.playlists : <Playlist>[];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر إنشاء قائمة جديدة دائماً في الأعلى
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showCreateDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: gold.withAlpha(isDark ? 25 : 15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: gold.withAlpha(isDark ? 90 : 60),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: gold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'إنشاء قائمة تشغيل جديدة',
                      style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: gold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (playlists.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.queue_music_rounded,
                        size: 36, color: gold.withAlpha(160)),
                    const SizedBox(height: 8),
                    Text(
                      'لا توجد قوائم تشغيل مخصصة حالياً',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              BlocBuilder<RecitationListCubit, RecitationListState>(
                builder: (context, recitationListState) {
                  final allRecitations = recitationListState is RecitationListLoaded
                      ? recitationListState.recitations
                      : <Recitation>[];
                  final recitationsMap = {for (var r in allRecitations) r.id: r};

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final playlist in playlists) ...[
                        _buildPlaylistCard(
                          context: context,
                          playlist: playlist,
                          recitationsMap: recitationsMap,
                          cardBg: cardBg,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildPlaylistCard({
    required BuildContext context,
    required Playlist playlist,
    required Map<String, Recitation> recitationsMap,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final created = playlist.createdAt ?? DateTime.now();
    final dateStr =
        '${created.year}/${created.month.toString().padLeft(2, '0')}/${created.day.toString().padLeft(2, '0')}';

    final effectiveRecitations = <Recitation>[
      ...playlist.recitations,
      ...playlist.recitationIds
          .where((id) => !playlist.recitations.any((r) => r.id == id))
          .map((id) => recitationsMap[id])
          .whereType<Recitation>(),
    ];

    final count = playlist.recitations.isNotEmpty
        ? playlist.recitations.length
        : playlist.recitationIds.length;

    final displayName = playlist.title.isNotEmpty
        ? playlist.title
        : (playlist.name.isNotEmpty ? playlist.name : 'قائمة تشغيل');

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlaylistDetailPage(playlistId: playlist.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: gold.withAlpha(isDark ? 35 : 20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.queue_music_rounded, color: gold, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count تلاوة  ·  تم الإنشاء: $dateStr',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.play_circle_fill_rounded,
                    size: 34,
                    color: gold,
                  ),
                  onPressed: () {
                    if (effectiveRecitations.isNotEmpty) {
                      context.read<AudioPlayerCubit>().play(
                        effectiveRecitations.first,
                        playlist: effectiveRecitations,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'قائمة التشغيل فارغة! أضف تلاوات أولاً.',
                            style: GoogleFonts.cairo(color: Colors.white),
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  tooltip: 'تشغيل القائمة',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.darkError,
                  ),
                  onPressed: () => _showDeleteDialog(
                    context,
                    playlist.id,
                    displayName,
                  ),
                  tooltip: 'حذف القائمة',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// باقي الويدجتس الخاصة بالصفحة الرئيسية كما هي دون تغيير
// ─────────────────────────────────────────────────────────
class _UnifiedHeroBanner extends StatelessWidget {
  final bool isDark;
  final Color gold;
  final ui.Image? portraitUiImage;

  const _UnifiedHeroBanner({
    required this.isDark,
    required this.gold,
    this.portraitUiImage,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [const Color(0xFF141D29), const Color(0xFF0D131C)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF1F5F9)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: isDark ? 0.25 : 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: gold,
                    size: 19,
                  ),
                  onPressed: () => context.read<ThemeCubit>().toggle(),
                  tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(5),
                  constraints: const BoxConstraints(),
                ),
              ),
              Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                style: GoogleFonts.amiri(
                  fontSize: 17.5,
                  color: gold.withValues(alpha: isDark ? 0.85 : 0.75),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.folder_special_outlined,
                    color: gold,
                    size: 19,
                  ),
                  onPressed: () => context.push('/downloads'),
                  tooltip: 'التلاوات المحمّلة',
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(5),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: 122,
            height: 122,
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gold.withValues(alpha: isDark ? 0.25 : 0.18),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: gold.withValues(alpha: isDark ? 0.4 : 0.3),
                width: 1.2,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: gold.withValues(alpha: isDark ? 0.9 : 0.75),
                  width: 1.6,
                ),
              ),
              child: ClipOval(
                child: portraitUiImage != null
                    ? RawImage(
                  image: portraitUiImage,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.25),
                )
                    : Image(
                  image: const ResizeImage(
                    AssetImage('assets/images/minshawi_portrait.jpg'),
                    width: 500,
                    height: 500,
                  ),
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.25),
                  errorBuilder: (context, error, stackTrace) {
                    return const Image(
                      image: ResizeImage(
                        AssetImage('assets/images/minshawi_portrait.jpg'),
                        width: 500,
                        height: 500,
                      ),
                      fit: BoxFit.cover,
                      alignment: Alignment(0, -0.25),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppConstants.sheikhNameAr,
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 21.5,
              fontWeight: FontWeight.w700,
              color: gold,
              letterSpacing: 0.2,
              height: 1.2,
              shadows: isDark
                  ? [
                Shadow(
                  color: gold.withValues(alpha: 0.3),
                  blurRadius: 18,
                ),
              ]
                  : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'رحمه الله تعالى • التلاوات النادرة والمصحف المرتل',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingSegmentedTabs extends StatelessWidget {
  final _LandingTab selectedTab;
  final bool isDark;
  final ValueChanged<_LandingTab> onTabSelected;

  const _LandingSegmentedTabs({
    required this.selectedTab,
    required this.isDark,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final bg = isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: _LandingTabButton(
              icon: Icons.auto_stories_outlined,
              label: 'المصاحف والتلاوات',
              isSelected: selectedTab == _LandingTab.collections,
              gold: gold,
              bg: bg,
              isDark: isDark,
              onTap: () => onTabSelected(_LandingTab.collections),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: BlocBuilder<PlaylistsCubit, PlaylistsState>(
              builder: (context, playlistState) {
                final count = playlistState is PlaylistsLoaded
                    ? playlistState.playlists.length
                    : 0;
                return _LandingTabButton(
                  icon: Icons.queue_music_rounded,
                  label: count > 0 ? 'قوائم التشغيل ($count)' : 'قوائم التشغيل',
                  isSelected: selectedTab == _LandingTab.playlists,
                  gold: gold,
                  bg: bg,
                  isDark: isDark,
                  onTap: () => onTabSelected(_LandingTab.playlists),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color gold;
  final Color bg;
  final bool isDark;
  final VoidCallback onTap;

  const _LandingTabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.gold,
    required this.bg,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? gold : bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? gold
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: 1.0,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: gold.withAlpha(isDark ? 60 : 35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected
                    ? (isDark ? AppColors.darkBackground : Colors.white)
                    : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? (isDark ? AppColors.darkBackground : Colors.white)
                        : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalCategoryCards extends StatelessWidget {
  final bool isDark;
  const _VerticalCategoryCards({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RepaintBoundary(
          child: _WideCategoryCard(
            title: 'المصحف المرتل كاملاً',
            subtitle: 'الختمة الكاملة برواية حفص عن عاصم',
            countBadge: '١١٤ سورة',
            isDark: isDark,
            onTap: () => context.push('/recitations/complete_murattal'),
          ),
        ),
        const SizedBox(height: 10),
        RepaintBoundary(
          child: _WideCategoryCard(
            title: 'المصحف المجود',
            subtitle: 'المصحف المجود كاملاً برواية حفص عن عاصم',
            countBadge: '١١٤ سورة',
            isDark: isDark,
            onTap: () => context.push('/recitations/mojawad'),
          ),
        ),
        const SizedBox(height: 10),
        RepaintBoundary(
          child: _WideCategoryCard(
            title: 'التلاوات النادرة',
            subtitle: 'تسجيلات ١٣٨٧ هـ الخارجية النادرة',
            countBadge: '٢٦ سورة',
            isDark: isDark,
            onTap: () => context.push('/recitations/rare_1387'),
          ),
        ),
      ],
    );
  }
}

class _WideCategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String countBadge;
  final bool isDark;
  final VoidCallback onTap;

  const _WideCategoryCard({
    required this.title,
    required this.subtitle,
    required this.countBadge,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    final textPrimary =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [const Color(0xFF15202B), const Color(0xFF0F1720)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF7F9FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: gold.withValues(alpha: isDark ? 0.25 : 0.35),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          splashColor: gold.withValues(alpha: 0.12),
          highlightColor: gold.withValues(alpha: 0.06),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 3.5,
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: isDark ? 0.85 : 0.95),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(10),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 18, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.amiri(
                                fontSize: 18.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                height: 1.25,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                              gold.withValues(alpha: isDark ? 0.12 : 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                gold.withValues(alpha: isDark ? 0.35 : 0.4),
                                width: 0.9,
                              ),
                            ),
                            child: Text(
                              countBadge,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: gold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 13,
                            color: gold.withValues(alpha: 0.75),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FramelessDeveloperFooter extends StatelessWidget {
  final bool isDark;
  const _FramelessDeveloperFooter({required this.isDark});

  Future<void> _launch(BuildContext context, String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذّر فتح الرابط',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: AppColors.darkError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذّر فتح الرابط الخارجي',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: AppColors.darkError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? Colors.white30 : Colors.black38;
    final iconColorHex = isDark ? '#6B7280' : '#9CA3AF';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'تطوير: ${AppConstants.devNameAr}',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textMuted,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FramelessSocialSvgIcon(
              svgString: _BrandVectors.facebook(iconColorHex),
              tooltip: 'فيسبوك',
              onTap: () => _launch(context, AppConstants.devFacebookUrl),
            ),
            const SizedBox(width: 8),
            _FramelessSocialSvgIcon(
              svgString: _BrandVectors.linkedin(iconColorHex),
              tooltip: 'لينكد إن',
              onTap: () => _launch(context, AppConstants.devLinkedinUrl),
            ),
            const SizedBox(width: 8),
            _FramelessSocialSvgIcon(
              svgString: _BrandVectors.github(iconColorHex),
              tooltip: 'جيت هب',
              onTap: () => _launch(context, AppConstants.devGithubUrl),
            ),
            const SizedBox(width: 8),
            _FramelessSocialSvgIcon(
              svgString: _BrandVectors.email(iconColorHex),
              tooltip: 'البريد الإلكتروني',
              onTap: () => _launch(context, AppConstants.devEmail),
            ),
          ],
        ),
      ],
    );
  }
}

class _FramelessSocialSvgIcon extends StatelessWidget {
  final String svgString;
  final String tooltip;
  final VoidCallback onTap;

  const _FramelessSocialSvgIcon({
    required this.svgString,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Tooltip(
            message: tooltip,
            child: SizedBox(
              width: 16,
              height: 16,
              child: SvgPicture.string(
                svgString,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

abstract class _BrandVectors {
  static String facebook(String color) => '''
<svg viewBox="0 0 24 24">
  <path fill="$color" d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
</svg>
''';

  static String linkedin(String color) => '''
<svg viewBox="0 0 24 24">
  <path fill="$color" d="M19 3a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h14m-.5 15.5v-5.3a3.26 3.26 0 0 0-3.26-3.26c-.85 0-1.84.52-2.28 1.3v-1.11h-2.79v8.37h2.79v-4.93c0-.77.62-1.4 1.39-1.4a1.4 1.4 0 0 1 1.4 1.4v4.93h2.75M6.46 10.9v7.6h2.8v-7.6h-2.8M7.86 6.3a1.63 1.63 0 0 0-1.63 1.63c0 .9.73 1.63 1.63 1.63.9 0 1.63-.73 1.63-1.63 0-.9-.73-1.63-1.63-1.63Z"/>
</svg>
''';

  static String github(String color) => '''
<svg viewBox="0 0 24 24">
  <path fill="$color" d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0 0 24 12c0-6.63-5.37-12-12-12z"/>
</svg>
''';

  static String email(String color) => '''
<svg viewBox="0 0 24 24">
  <path fill="$color" d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/>
</svg>
''';
}