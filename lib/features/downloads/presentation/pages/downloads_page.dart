import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/storage_service.dart';
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
import '../cubit/storage_cubit.dart';
import '../cubit/storage_state.dart';

/// Dedicated screen displaying all offline downloaded recitations with storage
/// breakdown, direct playback, cache cleanup, and single-tap delete confirmation.
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
    context.read<StorageCubit>().loadStorage();
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

    return MultiBlocListener(
      listeners: [
        BlocListener<StorageCubit, StorageState>(
          listener: (context, state) {
            if (state is StorageLoaded && state.successMessage != null) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF4ADE80),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.successMessage!,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF1E293B),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: gold.withAlpha(160),
                      width: 1.2,
                    ),
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
              context.read<StorageCubit>().clearMessage();
            } else if (state is StorageError) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: GoogleFonts.cairo(color: Colors.white),
                  ),
                  backgroundColor: AppColors.darkError,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        BlocListener<DownloadCubit, DownloadState>(
          listener: (context, state) {
            context.read<StorageCubit>().loadStorage();
          },
        ),
      ],
      child: Scaffold(
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

                return BlocBuilder<StorageCubit, StorageState>(
                  builder: (context, storageState) {
                    final StorageInfo info = storageState is StorageLoaded
                        ? storageState.storageInfo
                        : StorageInfo(
                            downloadedAudioBytes: 0,
                            downloadedSurahsCount: offlineRecitations.length,
                            cacheAndTempBytes: 0,
                          );
                    final isCleaning = storageState is StorageLoaded &&
                        storageState.isCleaning;

                    return Column(
                      children: [
                        _StorageBreakdownCard(
                          info: info,
                          isCleaning: isCleaning,
                          isDark: isDark,
                          gold: gold,
                          cardBg: cardBg,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onCleanCache: () =>
                              context.read<StorageCubit>().cleanCache(),
                        ),

                        if (offlineRecitations.isEmpty)
                          Expanded(
                            child: _EmptyDownloadsView(
                              isDark: isDark,
                              gold: gold,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                              addAutomaticKeepAlives: false,
                              addRepaintBoundaries: true,
                              itemCount: offlineRecitations.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final recitation = offlineRecitations[index];
                                final filePath =
                                    downloadedMap[recitation.id] ?? '';
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
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
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
              onTap: onPlay,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Surah Number Badge
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: gold.withAlpha(isDark ? 35 : 20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        Formatters.formatSurahNumber(recitation.surahNumber),
                        style: GoogleFonts.amiri(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: gold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Surah Title & Metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'سورة ${recitation.surahNameAr}',
                                style: GoogleFonts.amiri(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.offline_pin_rounded,
                                color: gold,
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${Formatters.formatDuration(recitation.durationSeconds)} · ${sizeMb.toStringAsFixed(1)} ميجابايت',
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
                        size: 34,
                        color: gold,
                      ),
                      onPressed: onPlay,
                      tooltip: isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 10),

                    // Delete Button
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      onPressed: onDelete,
                      tooltip: 'حذف التلاوة',
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: gold.withAlpha(isDark ? 30 : 20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_download_rounded,
                size: 40,
                color: gold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد تلاوات محملة حالياً',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكنك تحميل أي سورة للاستماع إليها بدون اتصال بالإنترنت في أي وقت.',
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

class _StorageBreakdownCard extends StatelessWidget {
  final StorageInfo info;
  final bool isCleaning;
  final bool isDark;
  final Color gold;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onCleanCache;

  const _StorageBreakdownCard({
    required this.info,
    required this.isCleaning,
    required this.isDark,
    required this.gold,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.onCleanCache,
  });

  @override
  Widget build(BuildContext context) {
    final downloadedStr =
        Formatters.formatFileSizeAr(info.downloadedAudioBytes);
    final cacheStr = Formatters.formatFileSizeAr(info.cacheAndTempBytes);
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: gold.withAlpha(isDark ? 80 : 50),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.storage_rounded, color: gold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'إدارة المساحة والذاكرة المؤقتة',
                    style: GoogleFonts.cairo(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              if (info.downloadedSurahsCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: gold.withAlpha(isDark ? 35 : 20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: gold.withAlpha(80), width: 0.8),
                  ),
                  child: Text(
                    '${info.downloadedSurahsCount} تلاوة',
                    style: GoogleFonts.cairo(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: gold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Two-Column Breakdown Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        (isDark ? Colors.white : Colors.black).withAlpha(8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.library_music_rounded,
                              color: gold, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'التلاوات المحملة',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        downloadedStr,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        (isDark ? Colors.white : Colors.black).withAlpha(8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_delete_outlined,
                              color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'الكاش والمؤقتة',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cacheStr,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Cleanup Action Button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: isCleaning ? null : onCleanCache,
              icon: isCleaning
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: gold,
                      ),
                    )
                  : Icon(Icons.cleaning_services_rounded,
                      size: 17, color: gold),
              label: Text(
                isCleaning
                    ? 'جارٍ تنظيف الذاكرة المؤقتة...'
                    : 'تنظيف الذاكرة المؤقتة',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: gold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: gold.withAlpha(isDark ? 100 : 80), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: gold.withAlpha(isDark ? 25 : 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
