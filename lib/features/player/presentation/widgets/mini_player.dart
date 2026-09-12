import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../favorites/presentation/cubit/favorites_state.dart';
import '../cubit/audio_player_cubit.dart';
import '../cubit/audio_player_state.dart';
import '../pages/audio_player_screen.dart';

/// Persistent bottom mini-player bar shown whenever a track is active.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      buildWhen: (prev, curr) {
        if ((prev is AudioPlayerIdle) != (curr is AudioPlayerIdle)) return true;
        if (prev.runtimeType != curr.runtimeType) return true;
        if (prev.currentRecitation?.id != curr.currentRecitation?.id) return true;
        if (prev is AudioPlayerReady && curr is AudioPlayerReady) {
          return prev.isPlaying != curr.isPlaying ||
              prev.isBuffering != curr.isBuffering;
        }
        return false;
      },
      builder: (context, state) {
        if (state is AudioPlayerIdle) return const SizedBox.shrink();
        return RepaintBoundary(child: _MiniPlayerContent(state: state));
      },
    );
  }
}

class _MiniPlayerContent extends StatelessWidget {
  final AudioPlayerState state;
  const _MiniPlayerContent({required this.state});

  void _openFullPlayer(BuildContext context, String? recitationId) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) {
          return AudioPlayerScreen(initialRecitationId: recitationId);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCardSurface : Colors.white;
    final gold = isDark ? const Color(0xFFE5B248) : const Color(0xFFD4A017);
    final borderColor =
        isDark ? const Color(0xFF2D333B) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    final cubit = context.read<AudioPlayerCubit>();

    final recitation = switch (state) {
      AudioPlayerLoading(:final recitation) => recitation,
      AudioPlayerReady(:final recitation) => recitation,
      AudioPlayerError(:final recitation) => recitation,
      _ => null,
    };

    final isLoading = state is AudioPlayerLoading;
    final isError = state is AudioPlayerError;
    final isPlaying =
        state is AudioPlayerReady && (state as AudioPlayerReady).isPlaying;
    final isBuffering =
        state is AudioPlayerReady && (state as AudioPlayerReady).isBuffering;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openFullPlayer(context, recitation?.id),
      onVerticalDragEnd: (details) {
        // Swipe-up gesture: trigger navigation if upward velocity exceeds 200
        if (details.primaryVelocity != null &&
            details.primaryVelocity! < -200) {
          _openFullPlayer(context, recitation?.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: borderColor, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 110 : 20),
              blurRadius: 18,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(child: _ProgressLine(gold: gold)),

            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 5, bottom: 3),
                width: 36,
                height: 3.5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF30363D) : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            SafeArea(
              top: false,
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    recitation?.surahNameAr ?? '',
                                    style: GoogleFonts.amiri(
                                      color: textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  size: 20,
                                  color: gold,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (recitation != null)
                                BlocBuilder<FavoritesCubit, FavoritesState>(
                                  builder: (context, favState) {
                                    final isFav =
                                        favState.isFavorite(recitation.id);
                                    return _IconTap(
                                      icon: isFav
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 20,
                                      color: isFav
                                          ? const Color(0xFFEF4444)
                                          : textSecondary,
                                      tooltip: isFav
                                          ? 'إزالة من المفضلة'
                                          : 'أضف إلى المفضلة',
                                      padding: const EdgeInsets.all(6),
                                      onTap: () => context
                                          .read<FavoritesCubit>()
                                          .toggleFavorite(recitation.id),
                                    );
                                  },
                                ),

                              const SizedBox(width: 4),

                              _IconTap(
                                icon: Icons.close_rounded,
                                size: 20,
                                color: textSecondary,
                                tooltip: 'إغلاق المشغل',
                                padding: const EdgeInsets.all(6),
                                onTap: () =>
                                    context.read<AudioPlayerCubit>().stop(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    RepaintBoundary(
                      child: _SeekBarRow(
                        gold: gold,
                        isDark: isDark,
                        isLoading: isLoading,
                        isError: isError,
                        textSecondary: textSecondary,
                        cubit: cubit,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _CtrlBtn(
                            icon: Icons.skip_previous_rounded,
                            size: 26,
                            color: isLoading || isError
                                ? textSecondary.withAlpha(70)
                                : textSecondary,
                            tooltip: 'السورة السابقة',
                            onPressed: isLoading || isError
                                ? null
                                : cubit.playPrevious,
                          ),

                          _CtrlBtn(
                            icon: Icons.replay_10_rounded,
                            size: 24,
                            color: isLoading || isError
                                ? textSecondary.withAlpha(70)
                                : textSecondary,
                            tooltip: 'تأخير ١٠ ثوانٍ (-10)',
                            onPressed: isLoading || isError
                                ? null
                                : cubit.skipBackward,
                          ),

                          _PlayPauseButton(
                            isLoading: isLoading,
                            isBuffering: isBuffering,
                            isPlaying: isPlaying,
                            isError: isError,
                            gold: gold,
                            isDark: isDark,
                            onTap: isError
                                ? (recitation != null
                                    ? () => cubit.play(recitation)
                                    : null)
                                : cubit.togglePlayPause,
                          ),

                          _CtrlBtn(
                            icon: Icons.forward_10_rounded,
                            size: 24,
                            color: isLoading || isError
                                ? textSecondary.withAlpha(70)
                                : textSecondary,
                            tooltip: 'تقديم ١٠ ثوانٍ (+10)',
                            onPressed: isLoading || isError
                                ? null
                                : cubit.skipForward,
                          ),

                          _CtrlBtn(
                            icon: Icons.skip_next_rounded,
                            size: 26,
                            color: isLoading || isError
                                ? textSecondary.withAlpha(70)
                                : textSecondary,
                            tooltip: 'السورة التالية',
                            onPressed:
                                isLoading || isError ? null : cubit.playNext,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final Color gold;
  const _ProgressLine({required this.gold});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      buildWhen: (prev, curr) {
        if (prev.runtimeType != curr.runtimeType) return true;
        if (curr is AudioPlayerReady && prev is AudioPlayerReady) {
          return prev.progress != curr.progress;
        }
        return false;
      },
      builder: (context, state) {
        final isLoading = state is AudioPlayerLoading;
        final p = state is AudioPlayerReady ? state.progress : 0.0;
        return LinearProgressIndicator(
          value: isLoading ? null : p.clamp(0.0, 1.0),
          minHeight: 2,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(gold),
        );
      },
    );
  }
}

class _SeekBarRow extends StatefulWidget {
  final Color gold;
  final bool isDark;
  final bool isLoading;
  final bool isError;
  final Color textSecondary;
  final AudioPlayerCubit cubit;

  const _SeekBarRow({
    required this.gold,
    required this.isDark,
    required this.isLoading,
    required this.isError,
    required this.textSecondary,
    required this.cubit,
  });

  @override
  State<_SeekBarRow> createState() => _SeekBarRowState();
}

class _SeekBarRowState extends State<_SeekBarRow> {
  bool _dragging = false;
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      buildWhen: (prev, curr) {
        if (prev.runtimeType != curr.runtimeType) return true;
        if (curr is AudioPlayerReady && prev is AudioPlayerReady) {
          return prev.progress != curr.progress ||
              prev.duration != curr.duration;
        }
        return false;
      },
      builder: (context, state) {
        final progress = state is AudioPlayerReady ? state.progress : 0.0;
        final position =
            state is AudioPlayerReady ? state.position : Duration.zero;
        final duration =
            state is AudioPlayerReady ? state.duration : Duration.zero;

        final sliderValue = _dragging ? _dragValue : progress.clamp(0.0, 1.0);
        final canInteract = !widget.isLoading && !widget.isError;
        final inactiveTrack =
            widget.isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 18,
              child: widget.isLoading || widget.isError
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: LinearProgressIndicator(
                        value: widget.isLoading ? null : 0,
                        minHeight: 2.5,
                        backgroundColor: inactiveTrack,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(widget.gold),
                      ),
                    )
                  : SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2.5,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 4.5,
                          disabledThumbRadius: 0,
                        ),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: widget.gold,
                        inactiveTrackColor: inactiveTrack,
                        thumbColor: widget.gold,
                        overlayColor: widget.gold.withAlpha(30),
                        trackShape: const RectangularSliderTrackShape(),
                      ),
                      child: Slider(
                        value: sliderValue,
                        min: 0,
                        max: 1,
                        onChangeStart: canInteract
                            ? (v) => setState(() {
                                  _dragging = true;
                                  _dragValue = v;
                                })
                            : null,
                        onChanged: canInteract
                            ? (v) => setState(() => _dragValue = v)
                            : null,
                        onChangeEnd: canInteract
                            ? (v) {
                                setState(() => _dragging = false);
                                widget.cubit.seekTo(Duration(
                                  milliseconds:
                                      (v * duration.inMilliseconds).round(),
                                ));
                              }
                            : null,
                      ),
                    ),
            ),

            if (!widget.isLoading && !widget.isError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Formatters.formatDurationObj(position),
                      style: GoogleFonts.cairo(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: widget.textSecondary,
                      ),
                    ),
                    Text(
                      Formatters.formatDurationObj(duration),
                      style: GoogleFonts.cairo(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: widget.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isLoading;
  final bool isBuffering;
  final bool isPlaying;
  final bool isError;
  final Color gold;
  final bool isDark;
  final VoidCallback? onTap;

  const _PlayPauseButton({
    required this.isLoading,
    required this.isBuffering,
    required this.isPlaying,
    required this.isError,
    required this.gold,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const iconColor = Color(0xFF12151A);
    final showSpinner = (isLoading || isBuffering) && !isPlaying;

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
            color: isError ? gold.withAlpha(120) : gold,
            boxShadow: [
              if (!isError)
                BoxShadow(
                  color: gold.withAlpha(isDark ? 90 : 50),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: showSpinner
              ? const Padding(
                  padding: EdgeInsets.all(11),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: iconColor,
                  ),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isError
                        ? Icons.replay_rounded
                        : (isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded),
                    key: ValueKey('$isPlaying-$isError'),
                    color: iconColor,
                    size: 27,
                  ),
                ),
        ),
      ),
    );
  }
}

class _IconTap extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final String tooltip;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const _IconTap({
    required this.icon,
    required this.size,
    required this.color,
    required this.tooltip,
    this.padding = const EdgeInsets.all(6),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: padding,
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  const _CtrlBtn({
    required this.icon,
    required this.size,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}
