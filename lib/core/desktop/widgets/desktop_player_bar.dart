import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import '../../router/app_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/favorites/presentation/cubit/favorites_cubit.dart';
import '../../../features/favorites/presentation/cubit/favorites_state.dart';
import '../../../features/player/presentation/cubit/audio_player_cubit.dart';
import '../../../features/player/presentation/cubit/audio_player_state.dart';
import '../../../features/player/presentation/widgets/sleep_timer_bottom_sheet.dart';
import '../../../features/recitations/domain/entities/recitation.dart';
import '../../../features/recitations/presentation/cubit/download_cubit.dart';
import '../../../features/recitations/presentation/cubit/download_state.dart';

class DesktopPlayerBar extends StatefulWidget {
  const DesktopPlayerBar({super.key});

  @override
  State<DesktopPlayerBar> createState() => _DesktopPlayerBarState();
}

class _DesktopPlayerBarState extends State<DesktopPlayerBar> {
  double _lastVolume = 1.0;
  DateTime _lastActionTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool _canPerformAction([int cooldownMs = 250]) {
    final now = DateTime.now();
    if (now.difference(_lastActionTime).inMilliseconds < cooldownMs) {
      return false;
    }
    _lastActionTime = now;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      buildWhen: (prev, curr) {
        if (prev is AudioPlayerReady && curr is AudioPlayerReady) {
          return prev.recitation.id != curr.recitation.id ||
              prev.isPlaying != curr.isPlaying ||
              prev.isBuffering != curr.isBuffering ||
              prev.speed != curr.speed ||
              prev.loopMode != curr.loopMode ||
              prev.isShuffleEnabled != curr.isShuffleEnabled ||
              prev.abLoopState != curr.abLoopState ||
              prev.duration != curr.duration;
        }
        return prev != curr;
      },
      builder: (context, state) {
        final cubit = context.read<AudioPlayerCubit>();

        final recitation = switch (state) {
          AudioPlayerReady(:final recitation) => recitation,
          AudioPlayerLoading(:final recitation) => recitation,
          AudioPlayerError(:final recitation) => recitation,
          _ => cubit.currentRecitation,
        };

        final ready = state is AudioPlayerReady ? state : null;
        final isPlaying = ready?.isPlaying ?? false;
        final isBuffering =
            (state is AudioPlayerLoading || (ready?.isBuffering ?? false)) &&
                !isPlaying;

        final isShuffle = ready?.isShuffleEnabled ?? cubit.isShuffleEnabled;
        final loopMode = ready?.loopMode ?? cubit.loopMode;
        final abState = ready?.abLoopState ?? cubit.abLoopState;
        final isAbActive = abState != AbLoopState.off;
        final speed = ready?.speed ?? cubit.speed;

        return Container(
          height: 94,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              top: BorderSide(color: border, width: 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 50 : 15),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildTrackInfo(
                  context: context,
                  recitation: recitation,
                  isDark: isDark,
                  gold: gold,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),

              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: isShuffle
                              ? 'إلغاء التشغيل العشوائي'
                              : 'تشغيل عشوائي للسور',
                          icon: Icon(
                            Icons.shuffle_rounded,
                            size: 19,
                            color: isShuffle ? gold : textSecondary,
                          ),
                          onPressed: recitation != null
                              ? () => cubit.toggleShuffle()
                              : null,
                        ),
                        IconButton(
                          tooltip: 'التلاوة السابقة',
                          icon: Icon(
                            Icons.skip_previous_rounded,
                            size: 24,
                            color: recitation != null
                                ? textPrimary
                                : textSecondary.withAlpha(100),
                          ),
                          onPressed: recitation != null
                              ? () {
                                  if (_canPerformAction(250)) cubit.playPrevious();
                                }
                              : null,
                        ),
                        IconButton(
                          tooltip: 'تأخير ١٠ ثوانٍ',
                          icon: Icon(
                            Icons.replay_10_rounded,
                            size: 21,
                            color: recitation != null
                                ? textPrimary
                                : textSecondary.withAlpha(100),
                          ),
                          onPressed: recitation != null
                              ? () {
                                  if (_canPerformAction(150)) cubit.skipBackward();
                                }
                              : null,
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: recitation != null
                              ? () {
                                  if (_canPerformAction(250)) cubit.togglePlayPause();
                                }
                              : null,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: recitation != null
                                    ? [
                                        gold,
                                        isDark
                                            ? AppColors.goldDark
                                            : const Color(0xFFB3861B),
                                      ]
                                    : [
                                        textSecondary.withAlpha(80),
                                        textSecondary.withAlpha(50),
                                      ],
                              ),
                              boxShadow: [
                                if (recitation != null)
                                  BoxShadow(
                                    color: gold.withAlpha(70),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: Center(
                              child: isBuffering
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      size: 26,
                                      color: Colors.black,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'تقديم ١٠ ثوانٍ',
                          icon: Icon(
                            Icons.forward_10_rounded,
                            size: 21,
                            color: recitation != null
                                ? textPrimary
                                : textSecondary.withAlpha(100),
                          ),
                          onPressed: recitation != null
                              ? () {
                                  if (_canPerformAction(150)) cubit.skipForward();
                                }
                              : null,
                        ),
                        IconButton(
                          tooltip: 'التلاوة التالية',
                          icon: Icon(
                            Icons.skip_next_rounded,
                            size: 24,
                            color: recitation != null
                                ? textPrimary
                                : textSecondary.withAlpha(100),
                          ),
                          onPressed: recitation != null
                              ? () {
                                  if (_canPerformAction(250)) cubit.playNext();
                                }
                              : null,
                        ),
                        IconButton(
                          tooltip: loopMode == LoopMode.one
                              ? 'تكرار التلاوة الحالية'
                              : (loopMode == LoopMode.all
                                  ? 'تكرار القائمة بالكامل'
                                  : 'التكرار متوقف'),
                          icon: Icon(
                            loopMode == LoopMode.one
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                            size: 20,
                            color: loopMode != LoopMode.off
                                ? gold
                                : textSecondary,
                          ),
                          onPressed: recitation != null
                              ? () => cubit.toggleLoopMode()
                              : null,
                        ),
                        IconButton(
                          tooltip: isAbActive
                              ? 'إلغاء تكرار A-B'
                              : 'تكرار مقطع للحفظ (A-B)',
                          icon: Icon(
                            Icons.repeat_on_rounded,
                            size: 19,
                            color: isAbActive ? gold : textSecondary,
                          ),
                          onPressed: recitation != null
                              ? () => cubit.cycleAbRepeat()
                              : null,
                        ),
                      ],
                    ),

                    _DesktopPlayerProgressBar(
                      cubit: cubit,
                      recitation: recitation,
                      gold: gold,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton<double>(
                      tooltip: 'سرعة التلاوة',
                      initialValue: speed,
                      offset: const Offset(0, -140),
                      color: isDark ? AppColors.darkCardSurface : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: border,
                          width: 1.0,
                        ),
                      ),
                      onSelected: (val) => cubit.setSpeed(val),
                      itemBuilder: (ctx) => [
                        for (final s in [0.75, 1.0, 1.25, 1.5])
                          PopupMenuItem<double>(
                            value: s,
                            child: Row(
                              children: [
                                if (speed == s)
                                  Icon(Icons.check_rounded,
                                      size: 16, color: gold)
                                else
                                  const SizedBox(width: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '${s}x',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: speed == s
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: speed == s ? gold : textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: border,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          '${speed}x',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: gold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    IconButton(
                      tooltip: 'مؤقت النوم',
                      icon: Icon(
                        Icons.bedtime_outlined,
                        size: 20,
                        color: textSecondary,
                      ),
                      onPressed: () => showSleepTimerBottomSheet(context),
                    ),

                    if (recitation != null)
                      BlocBuilder<DownloadCubit, DownloadState>(
                        builder: (context, downloadState) {
                          final isDownloading =
                              downloadState.isDownloading(recitation.id);
                          final isDownloaded = recitation.isDownloaded;

                          if (isDownloading) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.goldPrimary,
                                ),
                              ),
                            );
                          }

                          return IconButton(
                            tooltip: isDownloaded
                                ? 'التلاوة محملة محلياً'
                                : 'تحميل التلاوة للاستماع بدون إنترنت',
                            icon: Icon(
                              isDownloaded
                                  ? Icons.download_done_rounded
                                  : Icons.download_rounded,
                              size: 20,
                              color: isDownloaded
                                  ? AppColors.emeraldPrimary
                                  : textSecondary,
                            ),
                            onPressed: () {
                              final downloadCubit =
                                  context.read<DownloadCubit>();
                              if (isDownloaded) {
                                downloadCubit.deleteDownload(recitation);
                              } else {
                                downloadCubit.startDownload(recitation);
                              }
                            },
                          );
                        },
                      ),

                    IconButton(
                      tooltip: cubit.volume == 0 ? 'إلغاء الكتم' : 'كتم الصوت',
                      icon: Icon(
                        cubit.volume == 0
                            ? Icons.volume_off_rounded
                            : (cubit.volume < 0.5
                                ? Icons.volume_down_rounded
                                : Icons.volume_up_rounded),
                        size: 21,
                        color: textSecondary,
                      ),
                      onPressed: () {
                        if (cubit.volume > 0) {
                          _lastVolume = cubit.volume;
                          cubit.setVolume(0.0);
                        } else {
                          cubit.setVolume(_lastVolume > 0 ? _lastVolume : 1.0);
                        }
                        setState(() {});
                      },
                    ),
                    SizedBox(
                      width: 80,
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3.0,
                          activeTrackColor: gold,
                          inactiveTrackColor: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0),
                          thumbColor: gold,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 4.5,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 8,
                          ),
                        ),
                        child: Slider(
                          value: cubit.volume,
                          onChanged: (val) {
                            cubit.setVolume(val);
                            setState(() {});
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Builder(
                      builder: (context) {
                        final currentLoc =
                            GoRouterState.of(context).matchedLocation;
                        final isOnPlayer = currentLoc == AppRoutes.player;

                        return IconButton(
                          tooltip: isOnPlayer
                              ? 'تصغير المشغل (العودة)'
                              : 'مشغل التلاوات الكامل',
                          icon: Icon(
                            isOnPlayer
                                ? Icons.close_fullscreen_rounded
                                : Icons.open_in_full_rounded,
                            size: 19,
                            color: gold,
                          ),
                          onPressed: () {
                            if (!_canPerformAction(300)) return;
                            if (isOnPlayer) {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                final target =
                                    AppRouter.lastNonPlayerRoute.isNotEmpty
                                        ? AppRouter.lastNonPlayerRoute
                                        : AppRoutes.landing;
                                context.go(target);
                              }
                            } else {
                              context.go(AppRoutes.player, extra: recitation?.id);
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackInfo({
    required BuildContext context,
    required Recitation? recitation,
    required bool isDark,
    required Color gold,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (recitation == null) {
      return Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardSurface : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              image: const DecorationImage(
                image: ResizeImage(
                  AssetImage('assets/images/minshawi_portrait.jpg'),
                  width: 96,
                  height: 96,
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'جامع تلاوات المنشاوي',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              Text(
                'اختر سورة للبدء بالاستماع',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: gold.withAlpha(isDark ? 90 : 60),
              width: 1.0,
            ),
            image: const DecorationImage(
              image: ResizeImage(
                AssetImage('assets/images/minshawi_portrait.jpg'),
                width: 100,
                height: 100,
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                recitation.cleanSurahTitleWithVerses,
                style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (recitation.cleanLocationOrDetail.isNotEmpty)
                Text(
                  recitation.cleanLocationOrDetail,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: textSecondary,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        BlocBuilder<FavoritesCubit, FavoritesState>(
          builder: (context, favState) {
            final isFav = favState is FavoritesLoaded &&
                favState.isFavorite(recitation.id);
            return IconButton(
              tooltip: isFav ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                color: isFav ? AppColors.darkError : textSecondary,
                size: 20,
              ),
              onPressed: () {
                context.read<FavoritesCubit>().toggleFavorite(recitation.id);
              },
            );
          },
        ),
      ],
    );
  }
}


class _DesktopPlayerProgressBar extends StatefulWidget {
  final AudioPlayerCubit cubit;
  final Recitation? recitation;
  final Color gold;
  final Color textSecondary;
  final bool isDark;

  const _DesktopPlayerProgressBar({
    required this.cubit,
    required this.recitation,
    required this.gold,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  State<_DesktopPlayerProgressBar> createState() =>
      _DesktopPlayerProgressBarState();
}

class _DesktopPlayerProgressBarState extends State<_DesktopPlayerProgressBar> {
  bool _isDraggingSeek = false;
  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      buildWhen: (prev, curr) {
        if (prev is AudioPlayerReady && curr is AudioPlayerReady) {
          return prev.position != curr.position ||
              prev.duration != curr.duration ||
              prev.recitation.id != curr.recitation.id;
        }
        return prev != curr;
      },
      builder: (context, state) {
        final ready = state is AudioPlayerReady ? state : null;
        final position = ready?.position ?? Duration.zero;
        final duration = ready?.duration ?? Duration.zero;
        final maxDurationMs = duration.inMilliseconds.toDouble();
        final currentPositionMs = _isDraggingSeek
            ? _dragValue
            : position.inMilliseconds
                .toDouble()
                .clamp(0.0, maxDurationMs > 0 ? maxDurationMs : 1.0);

        return Row(
          children: [
            Text(
              Formatters.formatDurationObj(
                Duration(milliseconds: currentPositionMs.round()),
              ),
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: widget.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3.5,
                  activeTrackColor: widget.gold,
                  inactiveTrackColor: widget.isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFE2E8F0),
                  thumbColor: widget.gold,
                  overlayColor: widget.gold.withAlpha(40),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 5.5,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                ),
                child: Slider(
                  value: currentPositionMs,
                  max: maxDurationMs > 0 ? maxDurationMs : 1.0,
                  onChanged: widget.recitation != null && maxDurationMs > 0
                      ? (val) {
                          setState(() {
                            _isDraggingSeek = true;
                            _dragValue = val;
                          });
                        }
                      : null,
                  onChangeEnd: widget.recitation != null && maxDurationMs > 0
                      ? (val) {
                          widget.cubit.seekTo(
                            Duration(milliseconds: val.round()),
                          );
                          setState(() {
                            _isDraggingSeek = false;
                          });
                        }
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              Formatters.formatDurationObj(duration),
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: widget.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}
