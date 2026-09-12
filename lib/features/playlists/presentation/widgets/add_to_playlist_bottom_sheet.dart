import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../recitations/domain/entities/recitation.dart';
import '../cubit/playlists_cubit.dart';
import '../cubit/playlists_state.dart';

/// Modal bottom sheet allowing users to add/remove a recitation from their custom playlists
/// or create a new playlist on the fly.
class AddToPlaylistBottomSheet extends StatelessWidget {
  final Recitation recitation;

  const AddToPlaylistBottomSheet({
    super.key,
    required this.recitation,
  });

  static Future<void> show(BuildContext context, Recitation recitation) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddToPlaylistBottomSheet(recitation: recitation),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أدخل اسماً لقائمة التشغيل (مثال: تلاوات الفجر، المصحف المفضل):',
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
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
            ],
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
                  await context.read<PlaylistsCubit>().createPlaylist(
                        name,
                        initialRecitationId: recitation.id,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم إنشاء قائمة $name وإضافة سورة ${recitation.surahNameAr}',
                          style: GoogleFonts.cairo(color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF1E293B),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: Text(
                'إنشاء وإضافة',
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
    final bg = isDark ? const Color(0xFF161B26) : Colors.white;
    final cardBg =
        isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 160 : 60),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: textSecondary.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: gold.withAlpha(isDark ? 35 : 20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.playlist_add_rounded,
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
                          'إضافة إلى قائمة تشغيل',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'سورة ${recitation.surahNameAr} ()',
                          style: GoogleFonts.amiri(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _showCreatePlaylistDialog(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: gold.withAlpha(isDark ? 25 : 15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: gold.withAlpha(isDark ? 100 : 70),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Flexible(
              child: BlocBuilder<PlaylistsCubit, PlaylistsState>(
                builder: (context, state) {
                  if (state is PlaylistsLoading || state is PlaylistsInitial) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (state is PlaylistsLoaded) {
                    final playlists = state.playlists;
                    if (playlists.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.queue_music_rounded,
                              size: 48,
                              color: textSecondary.withAlpha(80),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد قوائم تشغيل حالياً',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'اضغط على الزر أعلاه لإنشاء قائمتك الأولى',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: textSecondary.withAlpha(160),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                      itemCount: playlists.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        final isInPlaylist =
                            playlist.recitationIds.contains(recitation.id);

                        return Container(
                          decoration: BoxDecoration(
                            color: isInPlaylist
                                ? gold.withAlpha(isDark ? 25 : 15)
                                : cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isInPlaylist
                                  ? gold.withAlpha(140)
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                              width: isInPlaylist ? 1.4 : 1.0,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                final cubit = context.read<PlaylistsCubit>();
                                if (isInPlaylist) {
                                  await cubit.removeRecitationFromPlaylist(
                                    playlist.id,
                                    recitation.id,
                                  );
                                } else {
                                  await cubit.addRecitationToPlaylist(
                                    playlist.id,
                                    recitation.id,
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.library_music_rounded,
                                      color: isInPlaylist ? gold : textSecondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            playlist.title,
                                            style: GoogleFonts.cairo(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: isInPlaylist
                                                  ? gold
                                                  : textPrimary,
                                            ),
                                          ),
                                          Text(
                                            '${playlist.recitationIds.length} تلاوة',
                                            style: GoogleFonts.cairo(
                                              fontSize: 11,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Checkbox(
                                      value: isInPlaylist,
                                      activeColor: gold,
                                      checkColor: isDark
                                          ? AppColors.darkBackground
                                          : Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      onChanged: (val) {
                                        context
                                            .read<PlaylistsCubit>()
                                            .toggleRecitationInPlaylist(
                                              playlist.id,
                                              recitation.id,
                                            );
                                      },
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

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
