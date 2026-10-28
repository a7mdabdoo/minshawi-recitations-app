import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/marquee_text.dart';
import '../../../player/presentation/cubit/audio_player_cubit.dart';
import '../../../player/presentation/cubit/audio_player_state.dart';
import '../../../player/presentation/widgets/mini_player.dart';
import '../../../recitations/domain/entities/recitation.dart';
import '../cubit/downloaded_recitations_cubit.dart';
import '../cubit/downloaded_recitations_state.dart';

class DownloadsPage extends StatefulWidget {
  final String? collectionId;
  const DownloadsPage({super.key, this.collectionId});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    context
        .read<DownloadedRecitationsCubit>()
        .loadDownloads(initialCollectionId: widget.collectionId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final Map<String, double> _fileSizeCache = {};

  double _getFileSizeMb(String path, int fallbackBytes) {
    if (kIsWeb) return 0.0;
    if (path.isEmpty) {
      return fallbackBytes > 0 ? fallbackBytes / (1024 * 1024) : 0.0;
    }
    final cached = _fileSizeCache[path];
    if (cached != null) return cached;
    try {
      final file = File(path);
      if (file.existsSync()) {
        final mb = file.lengthSync() / (1024 * 1024);
        _fileSizeCache[path] = mb;
        return mb;
      }
    } catch (_) {}
    final fallbackMb = fallbackBytes > 0 ? fallbackBytes / (1024 * 1024) : 0.0;
    _fileSizeCache[path] = fallbackMb;
    return fallbackMb;
  }

  String _getSectionTitle(String? collectionId) {
    switch (collectionId) {
      case 'complete_murattal':
        return 'المصحف المرتل';
      case 'mojawad':
        return 'المصحف المجود';
      case 'rare_1387':
        return 'التلاوات النادرة';
      case 'nahawand':
        return 'روائع النهاوند';
      default:
        return 'جميع الأقسام';
    }
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

    final isSectionSpecific =
        widget.collectionId != null && widget.collectionId!.isNotEmpty;
    final pageTitle = isSectionSpecific
        ? 'التلاوات المحمّلة • ${_getSectionTitle(widget.collectionId)}'
        : 'التلاوات المحمّلة';

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: const MiniPlayer(),
      appBar: AppBar(
        title: _isSearchExpanded
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.cairo(
                  fontSize: 14.5,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'ابحث في التلاوات المحمّلة...',
                  hintStyle: GoogleFonts.cairo(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (query) =>
                    context.read<DownloadedRecitationsCubit>().search(query),
              )
            : Text(
                pageTitle,
                style: GoogleFonts.amiri(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: gold,
                ),
              ),
        centerTitle: !_isSearchExpanded,
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: gold),
          onPressed: () {
            if (_isSearchExpanded) {
              setState(() {
                _isSearchExpanded = false;
                _searchController.clear();
                context.read<DownloadedRecitationsCubit>().search('');
              });
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.landing);
              }
            }
          },
          tooltip: 'رجوع',
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
              color: gold,
              size: 22,
            ),
            tooltip: _isSearchExpanded ? 'إلغاء البحث' : 'بحث في المحمّلات',
            onPressed: () {
              setState(() {
                if (_isSearchExpanded) {
                  _searchController.clear();
                  context.read<DownloadedRecitationsCubit>().search('');
                  _isSearchExpanded = false;
                } else {
                  _isSearchExpanded = true;
                }
              });
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<DownloadedRecitationsCubit, DownloadedRecitationsState>(
        builder: (context, state) {
          if (state is DownloadedRecitationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DownloadedRecitationsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.darkError,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      style: GoogleFonts.cairo(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                      ),
                      onPressed: () => context
                          .read<DownloadedRecitationsCubit>()
                          .loadDownloads(
                              initialCollectionId: widget.collectionId),
                      child: Text(
                        'إعادة المحاولة',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is! DownloadedRecitationsLoaded) {
            return const SizedBox.shrink();
          }

          final allCount = state.allDownloaded.length;
          final filteredRecitations = state.filteredDownloaded;

          if (allCount == 0) {
            return _EmptyDownloadsView(
              isDark: isDark,
              gold: gold,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            );
          }

          return Column(
            children: [
              _DownloadsHeader(
                allCount: allCount,
                filteredCount: filteredRecitations.length,
                totalSizeMb: state.totalSizeMb,
                selectedCollectionId: state.selectedCollectionId,
                isDark: isDark,
                gold: gold,
                cardBg: cardBg,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onCollectionSelected: (colId) => context
                    .read<DownloadedRecitationsCubit>()
                    .filterByCollection(colId),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: filteredRecitations.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_alt_off_rounded,
                                size: 44,
                                color: textSecondary.withAlpha(140),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                state.searchQuery.isNotEmpty
                                    ? 'لا توجد نتائج مطابقة لبحثك'
                                    : 'لا توجد تلاوات محمّلة في هذا القسم',
                                style: GoogleFonts.cairo(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  context
                                      .read<DownloadedRecitationsCubit>()
                                      .filterByCollection('all');
                                },
                                child: Text(
                                  'عرض جميع التلاوات المحمّلة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: gold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: true,
                        itemCount: filteredRecitations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final recitation = filteredRecitations[index];
                          final filePath = recitation.localFilePath ?? '';
                          final sizeMb = _getFileSizeMb(
                              filePath, recitation.fileSizeBytes);

                          return _DownloadedRecitationCard(
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
                              sizeMb > 0
                                  ? sizeMb
                                  : (recitation.fileSizeBytes / (1024 * 1024)),
                            ),
                            onPlay: () {
                              context.read<AudioPlayerCubit>().play(
                                    recitation,
                                    playlist: filteredRecitations,
                                  );
                            },
                          );
                        },
                      ),
              ),
            ],
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
            'هل ترغب في حذف ${recitation.surahNameAr} (${sizeMb.toStringAsFixed(1)} ميجابايت) لتحرير مساحة التخزين؟',
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
                if (recitation.localFilePath != null) {
                  _fileSizeCache.remove(recitation.localFilePath);
                }
                await context
                    .read<DownloadedRecitationsCubit>()
                    .deleteRecitation(recitation);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم حذف ${recitation.surahNameAr} وتحرير ${sizeMb.toStringAsFixed(1)} ميجابايت',
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

class _DownloadsHeader extends StatelessWidget {
  final int allCount;
  final int filteredCount;
  final double totalSizeMb;
  final String? selectedCollectionId;
  final bool isDark;
  final Color gold;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<String?> onCollectionSelected;

  const _DownloadsHeader({
    required this.allCount,
    required this.filteredCount,
    required this.totalSizeMb,
    required this.selectedCollectionId,
    required this.isDark,
    required this.gold,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.onCollectionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: gold.withAlpha(isDark ? 30 : 20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: gold.withAlpha(isDark ? 80 : 50),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sd_storage_rounded, size: 14, color: gold),
                    const SizedBox(width: 6),
                    Text(
                      'المساحة المستهلكة: ${totalSizeMb.toStringAsFixed(1)} م.ب',
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: gold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'إجمالي: $filteredCount تلاوة',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'الكل ($allCount)',
                  collectionId: null,
                  isSelected: selectedCollectionId == null ||
                      selectedCollectionId == 'all',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'المصحف المرتل',
                  collectionId: 'complete_murattal',
                  isSelected: selectedCollectionId == 'complete_murattal',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'المصحف المجود',
                  collectionId: 'mojawad',
                  isSelected: selectedCollectionId == 'mojawad',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'التلاوات النادرة',
                  collectionId: 'rare_1387',
                  isSelected: selectedCollectionId == 'rare_1387',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'روائع النهاوند',
                  collectionId: 'nahawand',
                  isSelected: selectedCollectionId == 'nahawand',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? collectionId,
    required bool isSelected,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => onCollectionSelected(collectionId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? gold : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? gold
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gold.withAlpha(isDark ? 60 : 35),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : textSecondary,
          ),
        ),
      ),
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
                        if (prevId == recitation.id ||
                            currId == recitation.id) {
                          if (prev is AudioPlayerReady &&
                              curr is AudioPlayerReady) {
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
                      MarqueeText(
                        text: recitation.surahNameAr.startsWith('سورة')
                            ? recitation.surahNameAr
                            : 'سورة ${recitation.surahNameAr}',
                        style: GoogleFonts.amiri(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: gold.withAlpha(isDark ? 30 : 20),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: gold.withAlpha(isDark ? 70 : 45),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              recitation.sourceLabel,
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: gold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '• ${Formatters.formatDuration(recitation.durationSeconds)}${recitation.trailingVerseOrLocation.isNotEmpty ? ' • ${recitation.trailingVerseOrLocation}' : ''} • ${sizeMb > 0 ? sizeMb.toStringAsFixed(1) : (recitation.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} م.ب',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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
