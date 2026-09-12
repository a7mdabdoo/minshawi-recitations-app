import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../favorites/presentation/cubit/favorites_state.dart';
import '../../../playlists/presentation/widgets/add_to_playlist_bottom_sheet.dart';
import '../../../recitations/domain/entities/recitation.dart';
import '../../../recitations/presentation/cubit/download_cubit.dart';
import '../../../recitations/presentation/cubit/download_state.dart';
import '../../../recitations/presentation/cubit/recitation_list_cubit.dart';
import '../../../recitations/presentation/cubit/recitation_list_state.dart';
import '../cubit/audio_player_cubit.dart';
import '../cubit/audio_player_state.dart';
import '../cubit/sleep_timer_cubit.dart';
import '../cubit/sleep_timer_state.dart';
import '../widgets/sleep_timer_bottom_sheet.dart';

/// Full-screen audio player for Quran recitations.
class AudioPlayerScreen extends StatefulWidget {
  final String? initialRecitationId;
  final ui.Image? portraitUiImage;

  const AudioPlayerScreen({
    super.key,
    this.initialRecitationId,
    this.portraitUiImage,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  double _volume = 1.0;
  double _lastNonZeroVolume = 1.0;

  @override
  void initState() {
    super.initState();
    _checkInitialTrack();
    final cubit = context.read<AudioPlayerCubit>();
    _volume = cubit.volume;
    if (_volume > 0) {
      _lastNonZeroVolume = _volume;
    }
  }

  void _checkInitialTrack() {
    final targetId = widget.initialRecitationId;
    if (targetId == null) return;

    final playerCubit = context.read<AudioPlayerCubit>();
    if (playerCubit.currentRecitation?.id == targetId) return;

    final listState = context.read<RecitationListCubit>().state;
    if (listState is RecitationListLoaded) {
      final match = listState.recitations.where((r) => r.id == targetId);
      if (match.isNotEmpty) {
        playerCubit.play(match.first);
      }
    }
  }

  String _getCollectionSubtitle(String? collectionId) {
    switch (collectionId) {
      case 'rare_1387':
        return 'التلاوات النادرة الخارجية - لعام ١٣٨٧ هـ';
      case 'mojawad':
        return 'المصحف المجود - رواية حفص عن عاصم';
      case 'complete_murattal':
      default:
        return 'المصحف المرتل - رواية حفص عن عاصم';
    }
  }

  void _showFeedback(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_outline_rounded,
    required Color gold,
    required bool isDark,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: gold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isDark ? AppColors.darkCardSurface : const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: gold.withAlpha(140),
            width: 1.2,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? const Color(0xFFE5B248) : const Color(0xFFD4A017);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);
    final cardSurface = isDark ? AppColors.darkCardSurface : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF2D333B) : const Color(0xFFE2E8F0);
    final inactiveTrackColor =
        isDark ? const Color(0xFF30363D) : const Color(0xFFCBD5E1);

    final bgGradient = isDark
        ? const [
            AppColors.darkCardSurface,
            AppColors.darkSurface,
            Color(0xFF12151A),
          ]
        : const [
            Color(0xFFF8FAFC),
            Color(0xFFF1F5F9),
            Color(0xFFE2E8F0),
          ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd: (details) {
          // Swipe-down gesture to dismiss/pop screen
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 200) {
            Navigator.of(context).maybePop();
          }
        },
        child: Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF12151A) : const Color(0xFFF8FAFC),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: bgGradient,
              ),
            ),
            child: SafeArea(
              child: BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
                buildWhen: (prev, curr) {
                  if (prev.runtimeType != curr.runtimeType) return true;
                  if (prev is AudioPlayerReady && curr is AudioPlayerReady) {
                    return prev.recitation.id != curr.recitation.id ||
                        prev.isPlaying != curr.isPlaying ||
                        prev.isBuffering != curr.isBuffering ||
                        prev.loopMode != curr.loopMode ||
                        prev.speed != curr.speed ||
                        prev.abPointA != curr.abPointA ||
                        prev.abPointB != curr.abPointB ||
                        prev.abRepeatCount != curr.abRepeatCount;
                  }
                  return false;
                },
                builder: (context, state) {
                  final cubit = context.read<AudioPlayerCubit>();
                  final recitation = switch (state) {
                    AudioPlayerReady(:final recitation) => recitation,
                    AudioPlayerLoading(:final recitation) => recitation,
                    AudioPlayerError(:final recitation) => recitation,
                    _ => cubit.currentRecitation,
                  };

                  if (recitation == null && state is AudioPlayerIdle) {
                    return _buildEmptyState(
                      context,
                      gold,
                      textPrimary,
                      textSecondary,
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final maxHeight = constraints.maxHeight;
                      final isTall = maxHeight > 680;
                      final portraitSize =
                          (maxHeight * 0.35).clamp(200.0, 260.0);

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: maxHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildTopBar(
                                  context,
                                  recitation,
                                  textPrimary,
                                  textSecondary,
                                ),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(height: isTall ? 6 : 2),

                                      _buildPortrait(
                                        portraitSize,
                                        gold,
                                        isDark,
                                      ),

                                      SizedBox(height: isTall ? 20 : 12),

                                      _buildTrackInfo(
                                        context,
                                        recitation,
                                        textPrimary,
                                        textSecondary,
                                      ),

                                      SizedBox(height: isTall ? 16 : 10),

                                      _PlayerSeekBarSection(
                                        gold: gold,
                                        textSecondary: textSecondary,
                                        inactiveTrackColor: inactiveTrackColor,
                                        cubit: cubit,
                                      ),

                                      SizedBox(height: isTall ? 12 : 8),

                                      _buildPrimaryControls(
                                        state,
                                        cubit,
                                        gold,
                                        textPrimary,
                                        textSecondary,
                                        isDark,
                                      ),

                                      SizedBox(height: isTall ? 16 : 10),

                                      _buildSecondaryToolsBar(
                                        context,
                                        recitation,
                                        state,
                                        cubit,
                                        gold,
                                        textSecondary,
                                        cardSurface,
                                        cardBorder,
                                        isDark,
                                      ),

                                      SizedBox(height: isTall ? 10 : 6),

                                      _buildVolumeSlider(
                                        context,
                                        cubit,
                                        gold,
                                        textSecondary,
                                        inactiveTrackColor,
                                      ),
                                    ],
                                  ),
                                ),

                                _buildBottomReturnButton(
                                  context,
                                  textSecondary,
                                  isDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildTopBar(
    BuildContext context,
    Recitation? recitation,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 32,
              color: textSecondary,
            ),
            tooltip: 'إغلاق',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Text(
            'مشغل التلاوات',
            style: GoogleFonts.cairo(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          if (recitation != null)
            IconButton(
              icon: Icon(
                Icons.playlist_add_rounded,
                size: 26,
                color: textSecondary,
              ),
              tooltip: 'إضافة لقائمة تشغيل',
              onPressed: () =>
                  AddToPlaylistBottomSheet.show(context, recitation),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }


  Widget _buildPortrait(double size, Color gold, bool isDark) {
    final imageFile = File('assets/images/minshawi_portrait.jpg');
    final hasLocalImage = imageFile.existsSync();

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 160 : 35),
              blurRadius: 26,
              offset: const Offset(0, 12),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: gold.withAlpha(isDark ? 30 : 25),
              blurRadius: 32,
              offset: const Offset(0, 6),
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: widget.portraitUiImage != null
              ? RawImage(
                  image: widget.portraitUiImage,
                  fit: BoxFit.cover,
                )
              : (hasLocalImage
                  ? Image(
                      image: ResizeImage(
                        FileImage(imageFile),
                        width: 500,
                        height: 500,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _fallbackPortrait(size, gold, isDark),
                    )
                  : Image(
                      image: const ResizeImage(
                        AssetImage('assets/images/minshawi_portrait.jpg'),
                        width: 500,
                        height: 500,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _fallbackPortrait(size, gold, isDark),
                    )),
        ),
      ),
    );
  }

  Widget _fallbackPortrait(double size, Color gold, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkCardSurface : const Color(0xFFE2E8F0),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: size * 0.45,
          color: gold,
        ),
      ),
    );
  }


  Widget _buildTrackInfo(
    BuildContext context,
    Recitation? recitation,
    Color textPrimary,
    Color textSecondary,
  ) {
    final surahTitle = recitation != null
        ? (recitation.surahNameAr.startsWith('سورة')
            ? recitation.surahNameAr
            : 'سورة ${recitation.surahNameAr}')
        : 'سورة الفاتحة';

    final collectionSub = recitation?.collectionId != null
        ? ' • ${_getCollectionSubtitle(recitation?.collectionId)}'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  surahTitle,
                  style: GoogleFonts.amiri(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'فضيلة الشيخ محمد صديق المنشاوي$collectionSub',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          if (recitation != null)
            BlocBuilder<FavoritesCubit, FavoritesState>(
              builder: (context, favState) {
                final isFav = favState.isFavorite(recitation.id);
                return IconButton(
                  icon: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 26,
                  ),
                  color: isFav ? const Color(0xFFEF4444) : textSecondary,
                  tooltip: isFav ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                  onPressed: () => context
                      .read<FavoritesCubit>()
                      .toggleFavorite(recitation.id),
                );
              },
            ),
        ],
      ),
    );
  }


  Widget _buildPrimaryControls(
    AudioPlayerState state,
    AudioPlayerCubit cubit,
    Color gold,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final isLoading = state is AudioPlayerLoading;
    final isError = state is AudioPlayerError;
    final isPlaying = state is AudioPlayerReady && state.isPlaying;
    final isBuffering = state is AudioPlayerReady && state.isBuffering;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              Icons.skip_previous_rounded,
              color: (isLoading || isError)
                  ? textSecondary.withAlpha(70)
                  : textPrimary,
              size: 28,
            ),
            tooltip: 'السورة السابقة',
            onPressed: (isLoading || isError) ? null : cubit.playPrevious,
          ),

          IconButton(
            icon: Icon(
              Icons.replay_10_rounded,
              color: (isLoading || isError)
                  ? textSecondary.withAlpha(70)
                  : textPrimary,
              size: 26,
            ),
            tooltip: 'تأخير ١٠ ثوانٍ',
            onPressed: (isLoading || isError) ? null : cubit.skipBackward,
          ),

          _buildPlayPauseFab(
            cubit: cubit,
            state: state,
            isPlaying: isPlaying,
            isInitialLoading: isLoading,
            isBuffering: isBuffering,
            isError: isError,
            gold: gold,
            isDark: isDark,
          ),

          IconButton(
            icon: Icon(
              Icons.forward_10_rounded,
              color: (isLoading || isError)
                  ? textSecondary.withAlpha(70)
                  : textPrimary,
              size: 26,
            ),
            tooltip: 'تقديم ١٠ ثوانٍ',
            onPressed: (isLoading || isError) ? null : cubit.skipForward,
          ),

          IconButton(
            icon: Icon(
              Icons.skip_next_rounded,
              color: (isLoading || isError)
                  ? textSecondary.withAlpha(70)
                  : textPrimary,
              size: 28,
            ),
            tooltip: 'السورة التالية',
            onPressed: (isLoading || isError) ? null : cubit.playNext,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseFab({
    required AudioPlayerCubit cubit,
    required AudioPlayerState state,
    required bool isPlaying,
    required bool isInitialLoading,
    required bool isBuffering,
    required bool isError,
    required Color gold,
    required bool isDark,
  }) {
    final showSpinner = (isInitialLoading || isBuffering) && !isPlaying;
    const iconColor = Color(0xFF12151A);

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isError
            ? (state.currentRecitation != null
                ? () => cubit.play(state.currentRecitation!)
                : null)
            : cubit.togglePlayPause,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: gold,
            boxShadow: [
              BoxShadow(
                color: gold.withAlpha(isDark ? 90 : 50),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: showSpinner
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: iconColor,
                    ),
                  )
                : Icon(
                    isError
                        ? Icons.replay_rounded
                        : (isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded),
                    size: 36,
                    color: iconColor,
                  ),
          ),
        ),
      ),
    );
  }


  Widget _buildSecondaryToolsBar(
    BuildContext context,
    Recitation? recitation,
    AudioPlayerState state,
    AudioPlayerCubit cubit,
    Color gold,
    Color textSecondary,
    Color cardSurface,
    Color cardBorder,
    bool isDark,
  ) {
    final currentSpeed = state is AudioPlayerReady ? state.speed : cubit.speed;
    final currentLoopMode =
        state is AudioPlayerReady ? state.loopMode : cubit.loopMode;
    final ready = state is AudioPlayerReady ? state : null;
    final abState = ready?.abLoopState ?? cubit.abLoopState;
    final isAbActive = abState != AbLoopState.off;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showSpeedDialog(
              context,
              cubit,
              currentSpeed,
              gold,
              cardSurface,
              cardBorder,
              isDark,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                currentSpeed == 1.0 ? '1.0x' : '${currentSpeed}x',
                style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: currentSpeed != 1.0 ? gold : textSecondary,
                ),
              ),
            ),
          ),

          BlocBuilder<SleepTimerCubit, SleepTimerState>(
            builder: (context, timerState) {
              final isActive = timerState.isActive;
              return Tooltip(
                message: isActive
                    ? (timerState.isEndOfSurah
                        ? 'مؤقت النوم: نهاية السورة'
                        : 'مؤقت النوم: متبقي ${timerState.remainingTime?.inMinutes ?? 0} د')
                    : 'مؤقت النوم',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => showSleepTimerBottomSheet(context),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          isActive
                              ? Icons.bedtime_rounded
                              : Icons.bedtime_outlined,
                          size: 22,
                          color: isActive ? gold : textSecondary,
                        ),
                        if (isActive)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: gold,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: gold.withAlpha(160),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          _buildRepeatButton(currentLoopMode, cubit, gold, textSecondary),

          Tooltip(
            message: 'تكرار مقطع للحفظ (A-B)',
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showAbRepeatBottomSheet(
                context,
                cubit,
                gold,
                cardSurface,
                cardBorder,
                isDark,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.repeat_on_rounded,
                      size: 19,
                      color: isAbActive ? gold : textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'A-B',
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isAbActive ? gold : textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (recitation != null)
            _buildDownloadButton(
              context,
              recitation,
              gold,
              textSecondary,
              isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildRepeatButton(
    LoopMode loopMode,
    AudioPlayerCubit cubit,
    Color gold,
    Color textSecondary,
  ) {
    final isActive = loopMode != LoopMode.off;
    final IconData icon = switch (loopMode) {
      LoopMode.one => Icons.repeat_one_rounded,
      _ => Icons.repeat_rounded,
    };
    final tooltip = switch (loopMode) {
      LoopMode.off => 'التكرار: معطل',
      LoopMode.all => 'التكرار: تكرار الكل',
      LoopMode.one => 'التكرار: تكرار السورة',
    };

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: cubit.toggleLoopMode,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 22,
            color: isActive ? gold : textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton(
    BuildContext context,
    Recitation recitation,
    Color gold,
    Color textSecondary,
    bool isDark,
  ) {
    return BlocBuilder<RecitationListCubit, RecitationListState>(
      builder: (context, listState) {
        final isDownloaded = recitation.isDownloaded ||
            (listState is RecitationListLoaded &&
                listState.recitations.any(
                    (r) => r.id == recitation.id && r.isDownloaded));

        return BlocBuilder<DownloadCubit, DownloadState>(
          builder: (context, dlState) {
            final isDownloading = dlState.isDownloading(recitation.id);
            final isPaused = dlState.isPaused(recitation.id);
            final progress = dlState.progressMap[recitation.id] ?? 0.0;

            if (isDownloading) {
              return Tooltip(
                message:
                    'جاري التنزيل ${(progress * 100).toInt()}% (اضغط للإيقاف)',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context
                      .read<DownloadCubit>()
                      .pauseDownload(recitation.id),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        value: progress > 0 ? progress : null,
                        strokeWidth: 2,
                        color: gold,
                      ),
                    ),
                  ),
                ),
              );
            }

            if (isPaused) {
              return Tooltip(
                message: 'استئناف التنزيل',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context
                      .read<DownloadCubit>()
                      .resumeDownload(recitation),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.pause_circle_outline_rounded,
                      size: 22,
                      color: gold,
                    ),
                  ),
                ),
              );
            }

            if (isDownloaded) {
              return Tooltip(
                message: 'التلاوة مُحمّلة ومتاحة بدون إنترنت',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    _showFeedback(
                      context,
                      'هذه التلاوة مُحمّلة بالفعل ومتاحة بدون إنترنت',
                      icon: Icons.check_circle_rounded,
                      gold: gold,
                      isDark: isDark,
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 22,
                      color: AppColors.downloadedColor,
                    ),
                  ),
                ),
              );
            }

            return Tooltip(
              message: 'تحميل السورة للاستماع بدون إنترنت',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  context.read<DownloadCubit>().startDownload(recitation);
                  _showFeedback(
                    context,
                    'بدء تحميل تلاوة ${recitation.surahNameAr}...',
                    icon: Icons.file_download_outlined,
                    gold: gold,
                    isDark: isDark,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.file_download_outlined,
                    size: 22,
                    color: textSecondary,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildVolumeSlider(
    BuildContext context,
    AudioPlayerCubit cubit,
    Color gold,
    Color textSecondary,
    Color inactiveTrackColor,
  ) {
    final isMuted = _volume <= 0.001;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isMuted ? Icons.volume_off_rounded : Icons.volume_mute_rounded,
              size: 20,
              color: isMuted ? gold : textSecondary,
            ),
            tooltip: isMuted ? 'إلغاء الكتم' : 'كتم الصوت',
            onPressed: () {
              setState(() {
                if (isMuted) {
                  _volume =
                      _lastNonZeroVolume > 0 ? _lastNonZeroVolume : 0.8;
                } else {
                  _lastNonZeroVolume = _volume;
                  _volume = 0.0;
                }
              });
              cubit.setVolume(_volume);
            },
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 4.5,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: gold.withAlpha(200),
                inactiveTrackColor: inactiveTrackColor,
                thumbColor: gold,
                overlayColor: gold.withAlpha(30),
                trackShape: const RectangularSliderTrackShape(),
              ),
              child: Slider(
                value: _volume.clamp(0.0, 1.0),
                min: 0.0,
                max: 1.0,
                onChanged: (val) {
                  setState(() {
                    _volume = val;
                    if (val > 0) _lastNonZeroVolume = val;
                  });
                  cubit.setVolume(val);
                },
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.volume_up_rounded,
              size: 20,
              color: textSecondary,
            ),
            tooltip: 'أعلى صوت',
            onPressed: () {
              setState(() {
                _volume = 1.0;
                _lastNonZeroVolume = 1.0;
              });
              cubit.setVolume(1.0);
            },
          ),
        ],
      ),
    );
  }


  Widget _buildBottomReturnButton(
    BuildContext context,
    Color textSecondary,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 2),
      child: Center(
        child: TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: textSecondary,
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? const Color(0xFF2D333B) : Colors.black12,
                width: 0.8,
              ),
            ),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: textSecondary,
          ),
          label: Text(
            'عرض قائمة السور',
            style: GoogleFonts.cairo(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ),
      ),
    );
  }


  void _showAbRepeatBottomSheet(
    BuildContext context,
    AudioPlayerCubit cubit,
    Color gold,
    Color cardSurface,
    Color cardBorder,
    bool isDark,
  ) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);
    final itemBg = isDark ? const Color(0xFF161B22) : const Color(0xFFF1F5F9);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
          builder: (context, state) {
            final ready = state is AudioPlayerReady ? state : null;
            final abState = ready?.abLoopState ?? cubit.abLoopState;
            final isPointASet = abState == AbLoopState.pointASet;
            final isActive = abState == AbLoopState.active;

            final pointA = ready?.abPointA ?? cubit.abPointA;
            final pointB = ready?.abPointB ?? cubit.abPointB;
            final repeatCount = ready?.abRepeatCount ?? cubit.abRepeatCount;
            final position = ready?.position ?? Duration.zero;
            final duration = ready?.duration ?? Duration.zero;

            final aLabel = pointA != null
                ? Formatters.formatDurationObj(pointA)
                : '--:--';
            final bLabel = pointB != null
                ? Formatters.formatDurationObj(pointB)
                : '--:--';
            final currentPosLabel = Formatters.formatDurationObj(position);

            return SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.repeat_on_rounded,
                                color: gold, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'تكرار مقطع للحفظ (A-B)',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              size: 20, color: textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: itemBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive ? gold.withAlpha(120) : cardBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الموضع الحالي: $currentPosLabel',
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? gold.withAlpha(40)
                                  : (isDark
                                      ? Colors.white.withAlpha(10)
                                      : Colors.black.withAlpha(8)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isActive
                                  ? '[$aLabel ➔ $bLabel]'
                                  : (isPointASet
                                      ? '[A: $aLabel ➔ ...]'
                                      : 'غير مفعّل'),
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isActive || isPointASet
                                    ? gold
                                    : textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildPointControlRow(
                      label: 'البداية A',
                      pointTime: pointA,
                      timeStr: aLabel,
                      isSet: isPointASet || isActive,
                      icon: Icons.flag_outlined,
                      onCapture: () {
                        cubit.setPointA();
                        final cur = cubit.abPointA ?? Duration.zero;
                        _showFeedback(
                          context,
                          'تم تحديد نقطة البداية A (${Formatters.formatDurationObj(cur)})',
                          icon: Icons.flag_outlined,
                          gold: gold,
                          isDark: isDark,
                        );
                      },
                      onNudgeMinus: () {
                        final base = pointA ?? position;
                        final newA = base > const Duration(seconds: 1)
                            ? base - const Duration(seconds: 1)
                            : Duration.zero;
                        cubit.setPointA(newA);
                      },
                      onNudgePlus: () {
                        final base = pointA ?? position;
                        var newA = base + const Duration(seconds: 1);
                        if (pointB != null && newA >= pointB) {
                          newA = pointB - const Duration(milliseconds: 500);
                        }
                        cubit.setPointA(newA);
                      },
                      gold: gold,
                      cardBorder: cardBorder,
                      itemBg: itemBg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 10),

                    _buildPointControlRow(
                      label: 'النهاية B',
                      pointTime: pointB,
                      timeStr: bLabel,
                      isSet: isActive,
                      icon: Icons.flag_rounded,
                      onCapture: () async {
                        await cubit.setPointB();
                        if (!context.mounted) return;
                        final pA = cubit.abPointA ?? Duration.zero;
                        final pB = cubit.abPointB ?? Duration.zero;
                        _showFeedback(
                          context,
                          'تم تفعيل التكرار: من ${Formatters.formatDurationObj(pA)} إلى ${Formatters.formatDurationObj(pB)}',
                          icon: Icons.repeat_on_rounded,
                          gold: gold,
                          isDark: isDark,
                        );
                      },
                      onNudgeMinus: () async {
                        final base = pointB ?? position;
                        var newB = base - const Duration(seconds: 1);
                        if (pointA != null && newB <= pointA) {
                          newB = pointA + const Duration(milliseconds: 500);
                        }
                        await cubit.setPointB(newB);
                      },
                      onNudgePlus: () async {
                        final base = pointB ?? position;
                        var newB = base + const Duration(seconds: 1);
                        if (duration > Duration.zero && newB > duration) {
                          newB = duration;
                        }
                        await cubit.setPointB(newB);
                      },
                      gold: gold,
                      cardBorder: cardBorder,
                      itemBg: itemBg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 14),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'عدد مرات التكرار:',
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildRepeatCountOption(
                              label: '٣ مرات',
                              count: 3,
                              currentCount: repeatCount,
                              onTap: () => cubit.setAbRepeatCount(3),
                              gold: gold,
                              cardBorder: cardBorder,
                              itemBg: itemBg,
                              textPrimary: textPrimary,
                            ),
                            const SizedBox(width: 8),
                            _buildRepeatCountOption(
                              label: '٥ مرات',
                              count: 5,
                              currentCount: repeatCount,
                              onTap: () => cubit.setAbRepeatCount(5),
                              gold: gold,
                              cardBorder: cardBorder,
                              itemBg: itemBg,
                              textPrimary: textPrimary,
                            ),
                            const SizedBox(width: 8),
                            _buildRepeatCountOption(
                              label: 'تكرار مستمر ∞',
                              count: null,
                              currentCount: repeatCount,
                              onTap: () => cubit.setAbRepeatCount(null),
                              gold: gold,
                              cardBorder: cardBorder,
                              itemBg: itemBg,
                              textPrimary: textPrimary,
                            ),
                          ],
                        ),
                      ],
                    ),

                    if (isPointASet || isActive) ...[
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          cubit.clearAbRepeat();
                          _showFeedback(
                            context,
                            'تم إيقاف تكرار A-B',
                            icon: Icons.stop_circle_outlined,
                            gold: gold,
                            isDark: isDark,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.darkError.withAlpha(25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.darkError.withAlpha(80),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.close_rounded,
                                  size: 16, color: AppColors.darkError),
                              const SizedBox(width: 6),
                              Text(
                                'إلغاء التكرار والعودة للوضع الطبيعي',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkError,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPointControlRow({
    required String label,
    required Duration? pointTime,
    required String timeStr,
    required bool isSet,
    required IconData icon,
    required VoidCallback onCapture,
    required VoidCallback onNudgeMinus,
    required VoidCallback onNudgePlus,
    required Color gold,
    required Color cardBorder,
    required Color itemBg,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSet ? gold.withAlpha(isDark ? 28 : 22) : itemBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSet ? gold.withAlpha(140) : cardBorder,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onCapture,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSet
                    ? gold
                    : (isDark
                        ? const Color(0xFF2D333B)
                        : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSet ? const Color(0xFF12151A) : textPrimary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'تحديد $label',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSet ? const Color(0xFF12151A) : textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          Text(
            timeStr,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isSet ? gold : textSecondary,
            ),
          ),

          const SizedBox(width: 10),

          _NudgeButton(
            label: '-1ث',
            enabled: pointTime != null,
            onTap: onNudgeMinus,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            isDark: isDark,
          ),
          const SizedBox(width: 4),
          _NudgeButton(
            label: '+1ث',
            enabled: pointTime != null,
            onTap: onNudgePlus,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatCountOption({
    required String label,
    required int? count,
    required int? currentCount,
    required VoidCallback onTap,
    required Color gold,
    required Color cardBorder,
    required Color itemBg,
    required Color textPrimary,
  }) {
    final isSelected = count == currentCount;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? gold : itemBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? gold : cardBorder,
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? const Color(0xFF12151A) : textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }


  void _showSpeedDialog(
    BuildContext context,
    AudioPlayerCubit cubit,
    double currentSpeed,
    Color gold,
    Color cardSurface,
    Color cardBorder,
    bool isDark,
  ) {
    final speeds = [0.75, 1.0, 1.25, 1.5];
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);
    final itemBg = isDark ? const Color(0xFF161B22) : const Color(0xFFF1F5F9);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'سرعة التلاوة',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 20, color: textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: speeds.map((s) {
                    final isSelected = s == currentSpeed;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            cubit.setSpeed(s);
                            Navigator.pop(ctx);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? gold : itemBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? gold : cardBorder,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${s == 1.0 ? '1.0' : s}x',
                                style: GoogleFonts.cairo(
                                  fontSize: 13.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFF12151A)
                                      : textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildEmptyState(
    BuildContext context,
    Color gold,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_off_rounded,
            size: 64,
            color: textSecondary.withAlpha(120),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد تلاوة مشغلة حالياً',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: const Color(0xFF12151A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(
              'العودة للتلاوات',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerSeekBarSection extends StatefulWidget {
  final Color gold;
  final Color textSecondary;
  final Color inactiveTrackColor;
  final AudioPlayerCubit cubit;

  const _PlayerSeekBarSection({
    required this.gold,
    required this.textSecondary,
    required this.inactiveTrackColor,
    required this.cubit,
  });

  @override
  State<_PlayerSeekBarSection> createState() => _PlayerSeekBarSectionState();
}

class _PlayerSeekBarSectionState extends State<_PlayerSeekBarSection> {
  bool _isDraggingSlider = false;
  double _dragSliderValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
        buildWhen: (prev, curr) {
          if (prev.runtimeType != curr.runtimeType) return true;
          if (prev is AudioPlayerReady && curr is AudioPlayerReady) {
            return prev.position != curr.position ||
                prev.duration != curr.duration;
          }
          return false;
        },
        builder: (context, state) {
          final isReady = state is AudioPlayerReady;
          final isLoading = state is AudioPlayerLoading;
          final isError = state is AudioPlayerError;

          final duration = isReady ? state.duration : Duration.zero;
          final position = isReady ? state.position : Duration.zero;

          final double rawProgress = duration.inMilliseconds > 0
              ? (position.inMilliseconds / duration.inMilliseconds)
                  .clamp(0.0, 1.0)
              : 0.0;
          final double currentSliderValue =
              _isDraggingSlider ? _dragSliderValue : rawProgress;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.0,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 5.0,
                    pressedElevation: 3.0,
                  ),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 12.0),
                  activeTrackColor: widget.gold,
                  inactiveTrackColor: widget.inactiveTrackColor,
                  thumbColor: widget.gold,
                  overlayColor: widget.gold.withAlpha(30),
                  trackShape: const RectangularSliderTrackShape(),
                ),
                child: Slider(
                  value: currentSliderValue,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (isLoading || isError)
                      ? null
                      : (val) {
                          setState(() {
                            _isDraggingSlider = true;
                            _dragSliderValue = val;
                          });
                        },
                  onChangeEnd: (val) {
                    setState(() {
                      _isDraggingSlider = false;
                    });
                    final targetMs = (val * duration.inMilliseconds).round();
                    widget.cubit.seekTo(Duration(milliseconds: targetMs));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Formatters.formatDurationObj(position),
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.textSecondary,
                      ).copyWith(fontFamilyFallback: const ['Arial', 'Cairo']),
                    ),

                    Text(
                      Formatters.formatDurationObj(duration),
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.textSecondary,
                      ).copyWith(fontFamilyFallback: const ['Arial', 'Cairo']),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NudgeButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final Color cardBorder;
  final Color textPrimary;
  final bool isDark;

  const _NudgeButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.cardBorder,
    required this.textPrimary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: enabled
              ? (isDark ? const Color(0xFF21262D) : const Color(0xFFE2E8F0))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? cardBorder : cardBorder.withAlpha(50),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: enabled ? textPrimary : textPrimary.withAlpha(70),
          ),
        ),
      ),
    );
  }
}
