import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../favorites/presentation/cubit/favorites_state.dart';
import '../cubit/audio_player_cubit.dart';
import '../cubit/audio_player_state.dart';
import '../cubit/sleep_timer_cubit.dart';
import '../cubit/sleep_timer_state.dart';
import 'sleep_timer_bottom_sheet.dart';

/// Persistent mini-player that slides up from the bottom of the screen
/// whenever a track is loaded. Displays track info, a seek bar, and
/// play/pause + skip controls.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      buildWhen: (previous, current) {
        if ((previous is AudioPlayerIdle) != (current is AudioPlayerIdle)) return true;
        if (previous.runtimeType != current.runtimeType) return true;
        if (previous.currentRecitation?.id != current.currentRecitation?.id) return true;
        if (previous is AudioPlayerReady && current is AudioPlayerReady) {
          return previous.isPlaying != current.isPlaying ||
              previous.isBuffering != current.isBuffering ||
              previous.isShuffleEnabled != current.isShuffleEnabled ||
              previous.speed != current.speed ||
              previous.loopMode != current.loopMode ||
              previous.abLoopState != current.abLoopState;
        }
        return false;
      },
      builder: (context, state) {
        // Hidden when idle.
        if (state is AudioPlayerIdle) return const SizedBox.shrink();

        return RepaintBoundary(child: _MiniPlayerContent(state: state));
      },
    );
  }
}

class _MiniPlayerContent extends StatelessWidget {
  final AudioPlayerState state;
  const _MiniPlayerContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // Extract shared info regardless of sub-state.
    final cubit = context.read<AudioPlayerCubit>();
    final isLoading = state is AudioPlayerLoading;
    final isError = state is AudioPlayerError;

    final recitation = switch (state) {
      AudioPlayerLoading(:final recitation) => recitation,
      AudioPlayerReady(:final recitation) => recitation,
      AudioPlayerError(:final recitation) => recitation,
      _ => null,
    };

    final isPlaying =
        state is AudioPlayerReady && (state as AudioPlayerReady).isPlaying;
    final isBuffering = state is AudioPlayerReady &&
        (state as AudioPlayerReady).isBuffering;

    final isShuffleActive = state is AudioPlayerReady
        ? (state as AudioPlayerReady).isShuffleEnabled
        : cubit.isShuffleEnabled;
    final currentSpeed = state is AudioPlayerReady
        ? (state as AudioPlayerReady).speed
        : cubit.speed;
    final currentLoopMode = state is AudioPlayerReady
        ? (state as AudioPlayerReady).loopMode
        : cubit.loopMode;

    return AnimatedSlide(
      offset: Offset.zero,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            top: BorderSide(color: gold.withAlpha(120), width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 80 : 20),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SeekBarSection(
                isDark: isDark,
                gold: gold,
                isLoading: isLoading,
                isError: isError,
              ),

              Directionality(
                textDirection: TextDirection.ltr,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => cubit.stop(),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Icon(
                                Icons.close_rounded,
                                size: 17,
                                color: textSecondary.withAlpha(180),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _DurationText(
                            state: state,
                            gold: gold,
                            textSecondary: textSecondary,
                            isError: isError,
                            isLoading: isLoading,
                            isBuffering: isBuffering,
                          ),
                        ],
                      ),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            recitation?.surahNameAr.replaceAll('سورة', '').trim() ?? '',
                            style: GoogleFonts.amiri(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16.5,
                            ),
                          ),
                          if (recitation != null) ...[
                            const SizedBox(width: 8),
                            BlocBuilder<FavoritesCubit, FavoritesState>(
                              builder: (context, favState) {
                                final isFav =
                                    favState.isFavorite(recitation.id);
                                return InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => context
                                      .read<FavoritesCubit>()
                                      .toggleFavorite(recitation.id),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: Icon(
                                      isFav
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 19,
                                      color: isFav
                                          ? const Color(0xFFEF4444)
                                          : textSecondary.withAlpha(160),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            BlocBuilder<SleepTimerCubit, SleepTimerState>(
                              builder: (context, timerState) {
                                final isActive = timerState.isActive;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () =>
                                      showSleepTimerBottomSheet(context),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Icon(
                                          isActive
                                              ? Icons.bedtime_rounded
                                              : Icons.bedtime_outlined,
                                          size: 19,
                                          color: isActive
                                              ? gold
                                              : textSecondary.withAlpha(160),
                                        ),
                                        if (isActive)
                                          Positioned(
                                            right: -1,
                                            top: -1,
                                            child: Container(
                                              width: 5,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                color: gold,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: isError
                                  ? null
                                  : () => _showSpeedDialog(
                                        context,
                                        cubit,
                                        currentSpeed,
                                        isDark,
                                        gold,
                                      ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: currentSpeed != 1.0
                                      ? gold.withAlpha(isDark ? 50 : 30)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: currentSpeed != 1.0
                                        ? gold
                                        : textSecondary.withAlpha(100),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${currentSpeed == 1.0 ? '1' : currentSpeed}x',
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: currentSpeed != 1.0
                                        ? gold
                                        : textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _AbRepeatButton(
                              cubit: cubit,
                              state: state,
                              isDark: isDark,
                              gold: gold,
                              textSecondary: textSecondary,
                              isError: isError,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ControlIconButton(
                        icon: Icons.shuffle_rounded,
                        color: isShuffleActive
                            ? gold
                            : textSecondary.withAlpha(130),
                        tooltip: isShuffleActive
                            ? 'الخلط: مفعل'
                            : 'الخلط: معطل',
                        size: 19,
                        onPressed: isError ? null : cubit.toggleShuffle,
                      ),

                      _ControlIconButton(
                        icon: Icons.skip_previous_rounded,
                        color: isLoading ? border : textSecondary,
                        tooltip: 'السورة السابقة',
                        size: 23,
                        onPressed: isLoading || isError
                            ? null
                            : cubit.playPrevious,
                      ),

                      _ControlIconButton(
                        icon: Icons.replay_10_rounded,
                        color: isLoading ? border : textSecondary,
                        tooltip: 'رجوع ١٠ ثوانٍ',
                        size: 20,
                        onPressed: isLoading || isError
                            ? null
                            : cubit.skipBackward,
                      ),

                      if (isError)
                        IconButton(
                          icon: Icon(
                            Icons.replay_rounded,
                            color: gold,
                            size: 24,
                          ),
                          onPressed: recitation != null
                              ? () => cubit.play(recitation)
                              : null,
                          tooltip: 'إعادة المحاولة',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      else
                        _PlayPauseButton(
                          isInitialLoading: isLoading,
                          isBuffering: isBuffering,
                          isPlaying: isPlaying,
                          gold: gold,
                          onTap: cubit.togglePlayPause,
                        ),

                      _ControlIconButton(
                        icon: Icons.forward_10_rounded,
                        color: isLoading ? border : textSecondary,
                        tooltip: 'تقديم ١٠ ثوانٍ',
                        size: 20,
                        onPressed: isLoading || isError
                            ? null
                            : cubit.skipForward,
                      ),

                      _ControlIconButton(
                        icon: Icons.skip_next_rounded,
                        color: isLoading ? border : textSecondary,
                        tooltip: 'السورة التالية',
                        size: 23,
                        onPressed: isLoading || isError
                            ? null
                            : cubit.playNext,
                      ),

                      _RepeatButton(
                        loopMode: currentLoopMode,
                        gold: gold,
                        textSecondary: textSecondary,
                        onTap: isError ? null : cubit.toggleLoopMode,
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
  }
}

class _SeekBarSection extends StatelessWidget {
  final bool isDark;
  final Color gold;
  final bool isLoading;
  final bool isError;

  const _SeekBarSection({
    required this.isDark,
    required this.gold,
    required this.isLoading,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AudioPlayerCubit>();
    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      buildWhen: (prev, curr) {
        if (prev.runtimeType != curr.runtimeType) return true;
        if (curr is AudioPlayerReady) {
          if (prev is! AudioPlayerReady) return true;
          return prev.progress != curr.progress ||
              prev.duration != curr.duration;
        }
        return false;
      },
      builder: (context, state) {
        final progress =
            state is AudioPlayerReady ? state.progress : 0.0;
        final duration =
            state is AudioPlayerReady ? state.duration : Duration.zero;

        return _SeekBar(
          progress: progress,
          duration: duration,
          isDark: isDark,
          gold: gold,
          onChanged: isLoading || isError
              ? null
              : (value) => cubit.seekTo(
                    Duration(
                      milliseconds:
                          (value * duration.inMilliseconds).round(),
                    ),
                  ),
        );
      },
    );
  }
}

class _DurationText extends StatelessWidget {
  final AudioPlayerState state;
  final Color gold;
  final Color textSecondary;
  final bool isError;
  final bool isLoading;
  final bool isBuffering;

  const _DurationText({
    required this.state,
    required this.gold,
    required this.textSecondary,
    required this.isError,
    required this.isLoading,
    required this.isBuffering,
  });

  @override
  Widget build(BuildContext context) {
    if (isError) {
      return Text(
        (state as AudioPlayerError).message,
        style: GoogleFonts.cairo(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: AppColors.darkError,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    if (isLoading || isBuffering) {
      return Text(
        isLoading ? 'جارٍ التحميل...' : 'جارٍ التخزين...',
        style: GoogleFonts.cairo(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: gold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      buildWhen: (prev, curr) {
        if (prev.runtimeType != curr.runtimeType) return true;
        if (curr is AudioPlayerReady) {
          if (prev is! AudioPlayerReady) return true;
          return prev.position.inSeconds != curr.position.inSeconds ||
              prev.duration.inSeconds != curr.duration.inSeconds;
        }
        return false;
      },
      builder: (context, readyState) {
        final position =
            readyState is AudioPlayerReady ? readyState.position : Duration.zero;
        final duration =
            readyState is AudioPlayerReady ? readyState.duration : Duration.zero;

        return Text(
          '${Formatters.formatDurationObj(position)} / ${Formatters.formatDurationObj(duration)}',
          style: GoogleFonts.cairo(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

class _SeekBar extends StatelessWidget {
  final double progress;
  final Duration duration;
  final bool isDark;
  final Color gold;
  final ValueChanged<double>? onChanged;

  const _SeekBar({
    required this.progress,
    required this.duration,
    required this.isDark,
    required this.gold,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (onChanged == null) {
      // Show a thin progress line while loading.
      return LinearProgressIndicator(
        value: null,
        minHeight: 2.5,
        backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        valueColor: AlwaysStoppedAnimation<Color>(gold),
      );
    }

    return SizedBox(
      height: 18,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2.5,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 4.5,
            disabledThumbRadius: 0.0,
          ),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
          activeTrackColor: gold,
          inactiveTrackColor:
              isDark ? AppColors.darkBorder : AppColors.lightBorder,
          thumbColor: gold,
          overlayColor: gold.withAlpha(30),
          trackShape: const RectangularSliderTrackShape(),
        ),
        child: Slider(
          value: progress,
          min: 0,
          max: 1,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isInitialLoading;
  final bool isBuffering;
  final bool isPlaying;
  final Color gold;
  final VoidCallback onTap;

  const _PlayPauseButton({
    required this.isInitialLoading,
    required this.isBuffering,
    required this.isPlaying,
    required this.gold,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.darkBackground : Colors.white;
    final showInitialSpinner = isInitialLoading && !isPlaying;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: gold,
            boxShadow: [
              BoxShadow(
                color: gold.withAlpha(isDark ? 80 : 40),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: showInitialSpinner
              ? Padding(
                  padding: const EdgeInsets.all(11),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: iconColor,
                  ),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    key: ValueKey(isPlaying),
                    color: iconColor,
                    size: 26,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ControlIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  const _ControlIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color, size: size),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: const EdgeInsets.all(3),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(),
      splashRadius: 16,
    );
  }
}

class _RepeatButton extends StatelessWidget {
  final LoopMode loopMode;
  final Color gold;
  final Color textSecondary;
  final VoidCallback? onTap;

  const _RepeatButton({
    required this.loopMode,
    required this.gold,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon = switch (loopMode) {
      LoopMode.one => Icons.repeat_one_rounded,
      _ => Icons.repeat_rounded,
    };

    final bool isActive = loopMode != LoopMode.off;
    final Color color = isActive ? gold : textSecondary.withAlpha(130);

    final String tooltip = switch (loopMode) {
      LoopMode.off => 'التكرار: معطل',
      LoopMode.all => 'التكرار: تكرار الكل',
      LoopMode.one => 'التكرار: تكرار السورة الحالية',
    };

    return IconButton(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: color, size: 19),
          if (loopMode == LoopMode.all)
            Positioned(
              bottom: 1,
              right: 1,
              child: Container(
                width: 3.5,
                height: 3.5,
                decoration: BoxDecoration(
                  color: gold,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      onPressed: onTap,
      tooltip: tooltip,
      padding: const EdgeInsets.all(3),
      constraints: const BoxConstraints(),
      splashRadius: 16,
    );
  }
}

void _showSpeedDialog(
  BuildContext context,
  AudioPlayerCubit cubit,
  double currentSpeed,
  bool isDark,
  Color gold,
) {
  final speeds = [0.75, 1.0, 1.25, 1.5];
  showModalBottomSheet<void>(
    context: context,
    backgroundColor:
        isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'سرعة التشغيل',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: speeds.map((s) {
                  final isSelected = s == currentSpeed;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? gold
                              : (isDark
                                  ? AppColors.darkBackground
                                  : const Color(0xFFF1F5F9)),
                          foregroundColor: isSelected
                              ? (isDark
                                  ? AppColors.darkBackground
                                  : Colors.white)
                              : (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected ? gold : Colors.transparent,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          cubit.setSpeed(s);
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          '${s == 1.0 ? '1.0' : s}x',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
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

class _AbRepeatButton extends StatelessWidget {
  final AudioPlayerCubit cubit;
  final AudioPlayerState state;
  final bool isDark;
  final Color gold;
  final Color textSecondary;
  final bool isError;

  const _AbRepeatButton({
    required this.cubit,
    required this.state,
    required this.isDark,
    required this.gold,
    required this.textSecondary,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final ready = state is AudioPlayerReady ? state as AudioPlayerReady : null;
    final abState = ready?.abLoopState ?? cubit.abLoopState;
    final isPointASet = abState == AbLoopState.pointASet;
    final isActive = abState == AbLoopState.active;

    final label = switch (abState) {
      AbLoopState.off => 'A-B',
      AbLoopState.pointASet => 'A ➔ ...',
      AbLoopState.active => 'A 🔁 B',
    };

    final tooltip = switch (abState) {
      AbLoopState.off => 'تكرار مقطع للحفظ (A-B)',
      AbLoopState.pointASet =>
        'تم تحديد البداية A (${Formatters.formatDurationObj(ready?.abPointA ?? cubit.abPointA ?? Duration.zero)}) - اضغط لتحديد B',
      AbLoopState.active => 'تكرار A-B نشط (اضغط للإلغاء)',
    };

    final bg = isActive
        ? gold.withAlpha(isDark ? 65 : 45)
        : (isPointASet
            ? gold.withAlpha(isDark ? 40 : 25)
            : Colors.transparent);

    final border =
        (isActive || isPointASet) ? gold : textSecondary.withAlpha(90);

    final textColor = (isActive || isPointASet) ? gold : textSecondary;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: isError
            ? null
            : () async {
                final nextState = await cubit.cycleAbRepeat();
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                final String message = switch (nextState) {
                  AbLoopState.pointASet =>
                    'تم تحديد نقطة البداية A (${Formatters.formatDurationObj(cubit.abPointA ?? Duration.zero)})',
                  AbLoopState.active =>
                    'تم تفعيل التكرار A-B (${Formatters.formatDurationObj(cubit.abPointA ?? Duration.zero)} ➔ ${Formatters.formatDurationObj(cubit.abPointB ?? Duration.zero)})',
                  AbLoopState.off => 'تم إيقاف تكرار A-B',
                };

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          nextState == AbLoopState.off
                              ? Icons.repeat_rounded
                              : Icons.repeat_on_rounded,
                          color: AppColors.goldPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
                        color: AppColors.goldPrimary.withAlpha(140),
                        width: 1.2,
                      ),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
