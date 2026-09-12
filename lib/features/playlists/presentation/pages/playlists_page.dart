import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../player/presentation/cubit/audio_player_cubit.dart';
import '../../../player/presentation/widgets/mini_player.dart';
import '../../../recitations/domain/entities/recitation.dart';
import '../../../recitations/presentation/cubit/recitation_list_cubit.dart';
import '../../../recitations/presentation/cubit/recitation_list_state.dart';
import '../../domain/entities/playlist.dart';
import '../cubit/playlists_cubit.dart';
import '../cubit/playlists_state.dart';
import 'playlist_detail_page.dart';

/// Standalone Playlists screen or embedded view for managing custom collections.
class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: const MiniPlayer(),
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'قوائم التشغيل المخصصة',
          style: GoogleFonts.amiri(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: gold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: gold),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'رجوع',
        ),
      ),
      body: const PlaylistsContentView(),
    );
  }
}

/// The reusable content body displaying custom playlists.
class PlaylistsContentView extends StatelessWidget {
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;

  const PlaylistsContentView({
    super.key,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
  });

  void _showCreateDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            'هل ترغب في حذف قائمة التشغيل $playlistTitle نهائياً؟',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final cardBg =
        isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return BlocBuilder<PlaylistsCubit, PlaylistsState>(
      builder: (context, state) {
        if (state is PlaylistsLoading || state is PlaylistsInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PlaylistsLoaded) {
          final playlists = state.playlists;

          if (playlists.isEmpty) {
            return Center(
              child: Padding(
                padding: padding ?? const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: gold.withAlpha(isDark ? 30 : 20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.queue_music_rounded,
                        size: 38,
                        color: gold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'لا توجد قوائم تشغيل مخصصة',
                      style: GoogleFonts.amiri(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أنشئ قوائم تشغيل لتنظيم تلاواتك المفضلة والاستماع إليها متتالية.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor:
                            isDark ? AppColors.darkBackground : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _showCreateDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(
                        'إنشاء قائمة جديدة',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return BlocBuilder<RecitationListCubit, RecitationListState>(
            builder: (context, recitationListState) {
              final allRecitations =
                  recitationListState is RecitationListLoaded
                      ? recitationListState.recitations
                      : <Recitation>[];
              final recitationsMap = {for (var r in allRecitations) r.id: r};

              return ListView.separated(
                physics: physics,
                shrinkWrap: shrinkWrap,
                padding: padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 96),
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                itemCount: playlists.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showCreateDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: gold.withAlpha(isDark ? 25 : 15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: gold.withAlpha(isDark ? 90 : 60),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline_rounded,
                                color: gold, size: 20),
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
                    );
                  }

                  final playlist = playlists[index - 1];
                  final playlistRecitations = playlist.recitationIds
                      .map((id) => recitationsMap[id])
                      .whereType<Recitation>()
                      .toList();

                  return RepaintBoundary(
                    child: _PlaylistOverviewCard(
                      playlist: playlist,
                      recitationsCount: playlist.recitationIds.length,
                      isDark: isDark,
                      gold: gold,
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PlaylistDetailPage(
                              playlistId: playlist.id,
                            ),
                          ),
                        );
                      },
                      onPlay: () {
                      if (playlistRecitations.isNotEmpty) {
                        context.read<AudioPlayerCubit>().play(
                              playlistRecitations.first,
                              playlist: playlistRecitations,
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
                    onDelete: () => _showDeleteDialog(
                      context,
                      playlist.id,
                      playlist.title,
                    ),
                  ),
                );
              },
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _PlaylistOverviewCard extends StatelessWidget {
  final Playlist playlist;
  final int recitationsCount;
  final bool isDark;
  final Color gold;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const _PlaylistOverviewCard({
    required this.playlist,
    required this.recitationsCount,
    required this.isDark,
    required this.gold,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: gold.withAlpha(isDark ? 35 : 20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.queue_music_rounded,
                    color: gold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.title,
                        style: GoogleFonts.cairo(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ' تلاوة  ·  تم الإنشاء: //',
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
                    size: 36,
                    color: gold,
                  ),
                  onPressed: onPlay,
                  tooltip: 'تشغيل القائمة كاملة',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),

                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: textSecondary,
                  ),
                  color: cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (val) {
                    if (val == 'open') onTap();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'open',
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new_rounded,
                              size: 18, color: gold),
                          const SizedBox(width: 10),
                          Text('فتح القائمة',
                              style: GoogleFonts.cairo(fontSize: 12.5)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.darkError),
                          const SizedBox(width: 10),
                          Text(
                            'حذف القائمة',
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              color: AppColors.darkError,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
