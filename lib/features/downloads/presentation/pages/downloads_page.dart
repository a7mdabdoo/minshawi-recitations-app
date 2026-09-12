import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/formatters.dart';
import '../../../player/presentation/cubit/audio_player_cubit.dart';
import '../../../player/presentation/cubit/audio_player_state.dart';
import '../../../player/presentation/widgets/mini_player.dart';
import '../../../recitations/data/datasources/local_recitation_data_source.dart';
import '../../../recitations/domain/entities/recitation.dart';
import '../../../recitations/presentation/cubit/download_cubit.dart';
import '../../../recitations/presentation/cubit/download_state.dart';
import '../../../recitations/presentation/cubit/recitation_list_cubit.dart';
import '../../../recitations/presentation/cubit/recitation_list_state.dart';

/// Dedicated screen displaying all offline downloaded recitations with
/// direct playback, and single-tap delete confirmation.
class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  late final LocalRecitationDataSource _localDataSource;

  @override
  void initState() {
    super.initState();
    _localDataSource = sl<LocalRecitationDataSource>();
    final listCubit = context.read<RecitationListCubit>();
    if (listCubit.state is RecitationListInitial) {
      listCubit.loadRecitations();
    }
  }

  double _getFileSizeMb(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        return file.lengthSync() / (1024 * 1024);
      }
    } catch (_) {}
    return 0.0;
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

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: const MiniPlayer(),
      appBar: AppBar(
        title: Text(
          'التلاوات المحمّلة',
          style: GoogleFonts.amiri(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: gold,
          ),
        ),
        centerTitle: true,
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: gold),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'رجوع',
        ),
      ),
      body: BlocBuilder<DownloadCubit, DownloadState>(
        builder: (context, downloadState) {
          return BlocBuilder<RecitationListCubit, RecitationListState>(
            builder: (context, listState) {
              if (listState is! RecitationListLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              final downloadedMap = _localDataSource.getAllDownloadedMap();
              final offlineRecitations = listState.recitations.where((r) {
                final path = downloadedMap[r.id];
                return path != null && File(path).existsSync();
              }).toList();

              if (offlineRecitations.isEmpty) {
                return _EmptyDownloadsView(
                  isDark: isDark,
                  gold: gold,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                itemCount: offlineRecitations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final recitation = offlineRecitations[index];
                  final filePath = downloadedMap[recitation.id] ?? '';
                  final sizeMb = _getFileSizeMb(filePath);

                  return RepaintBoundary(
                    child: _DownloadedRecitationCard(
                      recitation: recitation,
                      sizeMb: sizeMb,
                      isDark: isDark,
                      gold: gold,
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onDelete: () => _confirmDelete(
                        context,
                        recitation,
                        sizeMb,
                      ),
                      onPlay: () {
                        context.read<AudioPlayerCubit>().play(
                              recitation,
                              playlist: offlineRecitations,
                            );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Recitation recitation,
    double sizeMb,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'حذف التلاوة من الهاتف؟',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'هل ترغب في حذف سورة ${recitation.surahNameAr} (${sizeMb.toStringAsFixed(1)} ميجابايت) لتحرير مساحة التخزين؟',
            style: GoogleFonts.cairo(
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
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
                await context
                    .read<DownloadCubit>()
                    .deleteDownload(recitation);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم حذف سورة ${recitation.surahNameAr} وتحرير ${sizeMb.toStringAsFixed(1)} ميجابايت',
                        style: GoogleFonts.cairo(color: Colors.white),
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(
                'حذف الملف',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DownloadedRecitationCard extends StatelessWidget {
  final Recitation recitation;
  final double sizeMb;
  final bool isDark;
  final Color gold;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const _DownloadedRecitationCard({
    required this.recitation,
    required this.sizeMb,
    required this.isDark,
    required this.gold,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPlay,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: gold.withAlpha(isDark ? 35 : 25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
                      buildWhen: (prev, curr) {
                        if (prev.runtimeType != curr.runtimeType) return true;
                        final prevId = prev.currentRecitation?.id;
                        final currId = curr.currentRecitation?.id;
                        if (prevId == recitation.id || currId == recitation.id) {
                          if (prev is AudioPlayerReady && curr is AudioPlayerReady) {
                            return prev.isPlaying != curr.isPlaying;
                          }
                          return true;
                        }
                        return false;
                      },
                      builder: (context, playerState) {
                        final isCurrentTrack =
                            playerState.currentRecitation?.id == recitation.id;
                        final isPlaying = isCurrentTrack &&
                            playerState is AudioPlayerReady &&
                            playerState.isPlaying;

                        return Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: gold,
                          size: 24,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recitation.surahNameAr.startsWith('سورة')
                            ? recitation.surahNameAr
                            : 'سورة ${recitation.surahNameAr}',
                        style: GoogleFonts.amiri(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${Formatters.formatDuration(recitation.durationSeconds)} • ${sizeMb > 0 ? sizeMb.toStringAsFixed(1) : (recitation.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} ميجابايت',
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.darkError,
                    size: 22,
                  ),
                  tooltip: 'حذف التلاوة',
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyDownloadsView extends StatelessWidget {
  final bool isDark;
  final Color gold;
  final Color textPrimary;
  final Color textSecondary;

  const _EmptyDownloadsView({
    required this.isDark,
    required this.gold,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: gold.withAlpha(isDark ? 25 : 15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_download_outlined,
                size: 42,
                color: gold.withAlpha(200),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد تلاوات محمّلة حتى الآن',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكنك تحميل أي سورة للاستماع إليها لاحقاً دون الحاجة إلى اتصال بالإنترنت عبر زر التحميل بجانب كل سورة.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
