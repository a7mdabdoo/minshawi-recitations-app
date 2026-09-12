import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../player/presentation/cubit/audio_player_cubit.dart';
import '../../../player/presentation/cubit/audio_player_state.dart';
import '../../../player/presentation/widgets/mini_player.dart';
import '../../../recitations/domain/entities/recitation.dart';
import '../../../recitations/presentation/cubit/recitation_list_cubit.dart';
import '../../../recitations/presentation/cubit/recitation_list_state.dart';
import '../cubit/playlists_cubit.dart';
import '../cubit/playlists_state.dart';

/// Dedicated details screen for a custom playlist showing all contained recitations,
/// total duration, sequential playback, reordering/removal, and renaming.
class PlaylistDetailPage extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
  });

  void _showRenameDialog(BuildContext context, String currentTitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final cardBg =
        isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final controller = TextEditingController(text: currentTitle);

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'تعديل اسم قائمة التشغيل',
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
              hintText: 'اسم القائمة...',
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
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(dialogCtx).pop();
                  context.read<PlaylistsCubit>().renamePlaylist(playlistId, name);
                }
              },
              child: Text(
                'حفظ',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String playlistTitle) {
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
            'هل ترغب في حذف قائمة التشغيل $playlistTitle نهائياً؟ (لن يتم حذف ملفات التلاوات الأصلية).',
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
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                'حذف القائمة',
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
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg =
        isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return BlocBuilder<PlaylistsCubit, PlaylistsState>(
      builder: (context, playlistState) {
        if (playlistState is! PlaylistsLoaded) {
          return Scaffold(
            backgroundColor: bg,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final playlist = playlistState.getPlaylist(playlistId);
        if (playlist == null) {
          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: bg,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: gold),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: Text(
                'قائمة التشغيل غير موجودة أو تم حذفها',
                style: GoogleFonts.cairo(color: textSecondary, fontSize: 14),
              ),
            ),
          );
        }

        return BlocBuilder<RecitationListCubit, RecitationListState>(
          builder: (context, recitationListState) {
            final allRecitations = recitationListState is RecitationListLoaded
                ? recitationListState.recitations
                : <Recitation>[];

            // Resolve recitations in playlist order
            final recitationsMap = {for (var r in allRecitations) r.id: r};
            final playlistRecitations = playlist.recitationIds
                .map((id) => recitationsMap[id])
                .whereType<Recitation>()
                .toList();

            final totalSeconds = playlistRecitations.fold<int>(
              0,
              (sum, r) => sum + r.durationSeconds,
            );

            return Scaffold(
              backgroundColor: bg,
              bottomNavigationBar: const MiniPlayer(),
              appBar: AppBar(
                backgroundColor: bg,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  playlist.title,
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
                actions: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: gold, size: 20),
                    onPressed: () => _showRenameDialog(context, playlist.title),
                    tooltip: 'تعديل الاسم',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      size: 20,
                    ),
                    onPressed: () => _showDeleteDialog(context, playlist.title),
                    tooltip: 'حذف القائمة',
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              body: playlistRecitations.isEmpty
                  ? _EmptyPlaylistView(
                      isDark: isDark,
                      gold: gold,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      itemCount: playlistRecitations.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? [
                                          gold.withAlpha(45),
                                          AppColors.darkCardSurface,
                                        ]
                                      : [
                                          gold.withAlpha(30),
                                          AppColors.lightCardSurface,
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: gold.withAlpha(isDark ? 80 : 50),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(isDark ? 50 : 15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: gold.withAlpha(isDark ? 40 : 25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.playlist_play_rounded,
                                      color: gold,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${playlistRecitations.length} تلاوات',
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'إجمالي المدة: ${Formatters.formatDuration(totalSeconds)}',
                                          style: GoogleFonts.cairo(
                                            fontSize: 11.5,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: gold,
                                      foregroundColor: isDark
                                          ? AppColors.darkBackground
                                          : Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 20,
                                    ),
                                    label: Text(
                                      'تشغيل الكل',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onPressed: () {
                                      if (playlistRecitations.isNotEmpty) {
                                        context.read<AudioPlayerCubit>().play(
                                              playlistRecitations.first,
                                              playlist: playlistRecitations,
                                            );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final trackIndex = index - 1;
                        final recitation = playlistRecitations[trackIndex];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: RepaintBoundary(
                            child: _PlaylistRecitationCard(
                              recitation: recitation,
                              index: trackIndex + 1,
                              playlistRecitations: playlistRecitations,
                              isDark: isDark,
                              gold: gold,
                              cardBg: cardBg,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              onRemove: () {
                                context
                                    .read<PlaylistsCubit>()
                                    .removeRecitationFromPlaylist(
                                      playlistId,
                                      recitation.id,
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'تمت إزالة سورة ${recitation.surahNameAr} من القائمة',
                                      style: GoogleFonts.cairo(color: Colors.white),
                                    ),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}

class _PlaylistRecitationCard extends StatelessWidget {
  final Recitation recitation;
  final int index;
  final List<Recitation> playlistRecitations;
  final bool isDark;
  final Color gold;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onRemove;

  const _PlaylistRecitationCard({
    required this.recitation,
    required this.index,
    required this.playlistRecitations,
    required this.isDark,
    required this.gold,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      buildWhen: (prev, curr) {
        final prevCurrent = prev.currentRecitation?.id == recitation.id;
        final currCurrent = curr.currentRecitation?.id == recitation.id;
        final prevPlaying = prevCurrent && prev is AudioPlayerReady && prev.isPlaying;
        final currPlaying = currCurrent && curr is AudioPlayerReady && curr.isPlaying;
        return prevCurrent != currCurrent || prevPlaying != currPlaying;
      },
      builder: (context, playerState) {
        final isCurrent = playerState.currentRecitation?.id == recitation.id;
        final isPlaying = isCurrent &&
            playerState is AudioPlayerReady &&
            playerState.isPlaying;

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent
                  ? gold
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isCurrent ? 1.5 : 1.0,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                context.read<AudioPlayerCubit>().play(
                      recitation,
                      playlist: playlistRecitations,
                    );
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: gold.withAlpha(isDark ? 35 : 20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: gold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سورة ${recitation.surahNameAr}',
                            style: GoogleFonts.amiri(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${Formatters.formatDuration(recitation.durationSeconds)} · الآيات: ${recitation.verseRange}',
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
                        isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        size: 32,
                        color: gold,
                      ),
                      onPressed: () {
                        final playerCubit = context.read<AudioPlayerCubit>();
                        if (isCurrent && isPlaying) {
                          playerCubit.togglePlayPause();
                        } else {
                          playerCubit.play(
                            recitation,
                            playlist: playlistRecitations,
                          );
                        }
                      },
                      tooltip: isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),

                    IconButton(
                      icon: Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      onPressed: onRemove,
                      tooltip: 'إزالة من القائمة',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyPlaylistView extends StatelessWidget {
  final bool isDark;
  final Color gold;
  final Color textPrimary;
  final Color textSecondary;

  const _EmptyPlaylistView({
    required this.isDark,
    required this.gold,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                Icons.library_music_rounded,
                size: 38,
                color: gold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'قائمة التشغيل فارغة',
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أضف تلاوات إلى هذه القائمة من قائمة الخيارات (︙) في بطاقة أي سورة.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 12.5,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
