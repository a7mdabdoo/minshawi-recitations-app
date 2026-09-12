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

/// Modern, Spotify-inspired audio player screen for Quran recitations.
/// Features a deep midnight navy gradient background, prominent Sheikh portrait
/// with ambient drop shadow, sleek golden seekbar, responsive primary controls,
/// and a minimalist secondary tools bar for speed, sleep timer, repeat, A-B, and download.
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
  bool _isDraggingSlider = false;
  double _dragSliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    _checkInitialTrack();
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

  void _showFeedback(BuildContext context, String message,
      {IconData icon = Icons.info_outline_rounded}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: const Color(0xFFE5B248), size: 20),
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
        backgroundColor: const Color(0xFF16253B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: const Color(0xFFE5B248).withAlpha(140),
            width: 1.2,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFE5B248);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF121B2A),
                Color(0xFF0D1420),
                Color(0xFF0B0E14),
              ],
            ),
          ),
          child: SafeArea(
            child: BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
              builder: (context, state) {
                final cubit = context.read<AudioPlayerCubit>();
                final recitation = switch (state) {
                  AudioPlayerReady(:final recitation) => recitation,
                  AudioPlayerLoading(:final recitation) => recitation,
                  AudioPlayerError(:final recitation) => recitation,
                  _ => cubit.currentRecitation,
                };

                if (recitation == null && state is AudioPlayerIdle) {
                  return _buildEmptyState(context, gold);
                }

                return Column(
                  children: [
                    // ── Top Navigation Bar ─────────────────────────────────
                    _buildTopBar(context, recitation),

                    // ── Main Scrollable View ───────────────────────────────
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final portraitSize =
                              (constraints.maxHeight * 0.38).clamp(190.0, 250.0);

                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 6,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 6),

                                // 1. Sheikh Portrait with Ambient Shadow
                                _buildPortrait(portraitSize, gold),

                                const SizedBox(height: 22),

                                // 2. Track Info Header (Surah, Reciter, Heart)
                                _buildTrackInfo(context, recitation),

                                const SizedBox(height: 18),

                                // 3. Sleek Seek Bar & Timestamps
                                _buildSeekBarSection(state, cubit, gold),

                                const SizedBox(height: 12),

                                // 4. Primary Playback Controls
                                _buildPrimaryControls(state, cubit, gold),

                                const SizedBox(height: 18),

                                // 5. Spotify-Style Secondary Tools Bar
                                _buildSecondaryToolsBar(
                                  context,
                                  recitation,
                                  state,
                                  cubit,
                                  gold,
                                ),

                                const SizedBox(height: 16),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Top Navigation Bar ─────────────────────────────────────────────────────

  Widget _buildTopBar(
    BuildContext context,
    Recitation? recitation,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 32,
              color: Colors.white70,
            ),
            tooltip: 'إغلاق',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Text(
            'مشغل التلاوات',
            style: GoogleFonts.cairo(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (recitation != null)
            IconButton(
              icon: const Icon(
                Icons.playlist_add_rounded,
                size: 26,
                color: Colors.white70,
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

  // ── Portrait Art with Ambient Drop Shadow ───────────────────────────────────

  Widget _buildPortrait(double size, Color gold) {
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
              color: Colors.black.withAlpha(160),
              blurRadius: 28,
              offset: const Offset(0, 14),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: gold.withAlpha(35),
              blurRadius: 36,
              offset: const Offset(0, 8),
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
                  ? Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _fallbackPortrait(size, gold),
                    )
                  : Image.asset(
                      'assets/images/minshawi_portrait.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _fallbackPortrait(size, gold),
                    )),
        ),
      ),
    );
  }

  Widget _fallbackPortrait(double size, Color gold) {
    return Container(
      color: const Color(0xFF16253B),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: size * 0.45,
          color: gold,
        ),
      ),
    );
  }

  // ── Track Header: Surah Name, Reciter & Favorite Heart ─────────────────────

  Widget _buildTrackInfo(
    BuildContext context,
    Recitation? recitation,
  ) {
    final surahTitle = recitation != null
        ? (recitation.surahNameAr.startsWith('سورة')
            ? recitation.surahNameAr
            : 'سورة ${recitation.surahNameAr}')
        : 'سورة الفاتحة';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Surah Name & Narration Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  surahTitle,
                  style: GoogleFonts.amiri(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'الشيخ محمد صديق المنشاوي • ${_getCollectionSubtitle(recitation?.collectionId)}',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Favorite Heart Button (Spotify style aligned beside title)
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
                  color:
                      isFav ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
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

  // ── Seek Bar & Timestamps ──────────────────────────────────────────────────

  Widget _buildSeekBarSection(
    AudioPlayerState state,
    AudioPlayerCubit cubit,
    Color gold,
  ) {
    final isReady = state is AudioPlayerReady;
    final isLoading = state is AudioPlayerLoading;
    final isError = state is AudioPlayerError;

    final duration = isReady ? state.duration : Duration.zero;
    final position = isReady ? state.position : Duration.zero;

    final double rawProgress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
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
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
            activeTrackColor: gold,
            inactiveTrackColor: Colors.white.withAlpha(35),
            thumbColor: gold,
            overlayColor: gold.withAlpha(30),
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
              cubit.seekTo(Duration(milliseconds: targetMs));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Elapsed duration (right side in RTL)
              Text(
                Formatters.formatDurationObj(position),
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ).copyWith(fontFamilyFallback: const ['Arial', 'Cairo']),
              ),

              // Total duration (left side in RTL)
              Text(
                Formatters.formatDurationObj(duration),
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ).copyWith(fontFamilyFallback: const ['Arial', 'Cairo']),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Primary Playback Controls ──────────────────────────────────────────────

  Widget _buildPrimaryControls(
    AudioPlayerState state,
    AudioPlayerCubit cubit,
    Color gold,
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
          // Previous Surah (size: 28)
          IconButton(
            icon: Icon(
              Icons.skip_previous_rounded,
              color: (isLoading || isError) ? Colors.white38 : Colors.white,
              size: 28,
            ),
            tooltip: 'السورة السابقة',
            onPressed: (isLoading || isError) ? null : cubit.playPrevious,
          ),

          // Seek -10s (size: 26)
          IconButton(
            icon: Icon(
              Icons.replay_10_rounded,
              color: (isLoading || isError) ? Colors.white38 : Colors.white,
              size: 26,
            ),
            tooltip: 'تأخير ١٠ ثوانٍ',
            onPressed: (isLoading || isError) ? null : cubit.skipBackward,
          ),

          // Large Play/Pause FAB Button (size: ~64x64, gold with soft glow)
          _buildPlayPauseFab(
            cubit: cubit,
            state: state,
            isPlaying: isPlaying,
            isInitialLoading: isLoading,
            isBuffering: isBuffering,
            isError: isError,
            gold: gold,
          ),

          // Seek +10s (size: 26)
          IconButton(
            icon: Icon(
              Icons.forward_10_rounded,
              color: (isLoading || isError) ? Colors.white38 : Colors.white,
              size: 26,
            ),
            tooltip: 'تقديم ١٠ ثوانٍ',
            onPressed: (isLoading || isError) ? null : cubit.skipForward,
          ),

          // Next Surah (size: 28)
          IconButton(
            icon: Icon(
              Icons.skip_next_rounded,
              color: (isLoading || isError) ? Colors.white38 : Colors.white,
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
  }) {
    final showSpinner = (isInitialLoading || isBuffering) && !isPlaying;
    const iconColor = Color(0xFF0B0E14);

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
                color: gold.withAlpha(90),
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

  // ── 5. Spotify-Style Secondary Tools Bar (Minimalist Icon Row) ─────────────

  Widget _buildSecondaryToolsBar(
    BuildContext context,
    Recitation? recitation,
    AudioPlayerState state,
    AudioPlayerCubit cubit,
    Color gold,
  ) {
    final currentSpeed = state is AudioPlayerReady ? state.speed : cubit.speed;
    final currentLoopMode =
        state is AudioPlayerReady ? state.loopMode : cubit.loopMode;
    final ready = state is AudioPlayerReady ? state : null;
    final abState = ready?.abLoopState ?? cubit.abLoopState;
    final isAbActive = abState != AbLoopState.off;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Speed: Minimal text button (e.g. 1.0x in white/gold)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showSpeedDialog(context, cubit, currentSpeed, gold),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                currentSpeed == 1.0 ? '1.0x' : '${currentSpeed}x',
                style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: currentSpeed != 1.0
                      ? gold
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),

          // 2. Sleep Timer: Sleek bedtime icon (turns gold with dot when active)
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
                          color: isActive
                              ? gold
                              : const Color(0xFF94A3B8),
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

          // 3. Repeat Mode: Icons.repeat / Icons.repeat_one (turns gold when active)
          _buildRepeatButton(currentLoopMode, cubit, gold),

          // 4. A-B Repeat: Minimal icon/pill opening bottom modal sheet
          Tooltip(
            message: 'تكرار مقطع للحفظ (A-B)',
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showAbRepeatBottomSheet(context, cubit),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.repeat_on_rounded,
                      size: 19,
                      color: isAbActive
                          ? gold
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'A-B',
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isAbActive
                            ? gold
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Offline Download: Icons.file_download_outlined (turns into checkmark if downloaded)
          if (recitation != null)
            _buildDownloadButton(context, recitation, gold),
        ],
      ),
    );
  }

  Widget _buildRepeatButton(
    LoopMode loopMode,
    AudioPlayerCubit cubit,
    Color gold,
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
            color: isActive ? gold : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton(
    BuildContext context,
    Recitation recitation,
    Color gold,
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
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.file_download_outlined,
                    size: 22,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── A-B Repeat Modal Bottom Sheet ──────────────────────────────────────────

  void _showAbRepeatBottomSheet(
    BuildContext context,
    AudioPlayerCubit cubit,
  ) {
    const gold = Color(0xFFE5B248);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF16253B),
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
            final position = ready?.position ?? Duration.zero;

            final aLabel =
                pointA != null ? Formatters.formatDurationObj(pointA) : '--:--';
            final bLabel =
                pointB != null ? Formatters.formatDurationObj(pointB) : '--:--';
            final currentPosLabel = Formatters.formatDurationObj(position);

            return SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.repeat_on_rounded,
                                color: gold, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'تكرار مقطع للحفظ (A-B)',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 20, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Current status banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1A2A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? gold.withAlpha(120) : Colors.white10,
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
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? gold.withAlpha(40)
                                  : Colors.white.withAlpha(10),
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
                                    : Colors.white60,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Action Buttons: Set A & Set B
                    Row(
                      children: [
                        // Set Point A
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              cubit.setPointA();
                              final cur = cubit.abPointA ?? Duration.zero;
                              _showFeedback(
                                context,
                                'تم تحديد نقطة البداية A (${Formatters.formatDurationObj(cur)})',
                                icon: Icons.flag_outlined,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isPointASet || isActive
                                    ? gold.withAlpha(45)
                                    : const Color(0xFF0F1A2A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isPointASet || isActive
                                      ? gold
                                      : Colors.white24,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.flag_outlined,
                                    size: 18,
                                    color: isPointASet || isActive
                                        ? gold
                                        : Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    pointA != null
                                        ? 'A: $aLabel'
                                        : 'تحديد البداية A',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isPointASet || isActive
                                          ? gold
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Set Point B
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              await cubit.setPointB();
                              if (!context.mounted) return;
                              final pA = cubit.abPointA ?? Duration.zero;
                              final pB = cubit.abPointB ?? Duration.zero;
                              _showFeedback(
                                context,
                                'تم تفعيل التكرار: من ${Formatters.formatDurationObj(pA)} إلى ${Formatters.formatDurationObj(pB)}',
                                icon: Icons.repeat_on_rounded,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? gold.withAlpha(45)
                                    : const Color(0xFF0F1A2A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isActive ? gold : Colors.white24,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.flag_rounded,
                                    size: 18,
                                    color:
                                        isActive ? gold : Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    pointB != null
                                        ? 'B: $bLabel'
                                        : 'تحديد النهاية B',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isActive ? gold : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (isPointASet || isActive) ...[
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          cubit.clearAbRepeat();
                          _showFeedback(context, 'تم إيقاف تكرار A-B',
                              icon: Icons.stop_circle_outlined);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.darkError.withAlpha(30),
                            borderRadius: BorderRadius.circular(16),
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

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Speed Selector Modal ───────────────────────────────────────────────────

  void _showSpeedDialog(
    BuildContext context,
    AudioPlayerCubit cubit,
    double currentSpeed,
    Color gold,
  ) {
    final speeds = [0.75, 1.0, 1.25, 1.5];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF16253B),
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
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: Colors.white70),
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
                              color: isSelected
                                  ? gold
                                  : const Color(0xFF0F1A2A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? gold : Colors.white12,
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
                                      ? const Color(0xFF0B1017)
                                      : Colors.white,
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

  // ── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmptyState(
    BuildContext context,
    Color gold,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_off_rounded,
            size: 64,
            color: const Color(0xFF94A3B8).withAlpha(120),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد تلاوة مشغلة حالياً',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: const Color(0xFF0B1017),
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
