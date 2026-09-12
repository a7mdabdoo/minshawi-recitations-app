import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../favorites/presentation/cubit/favorites_state.dart';
import '../cubit/audio_player_cubit.dart';
import '../cubit/audio_player_state.dart';

/// Persistent bottom mini-player shown whenever a track is active.
/// Two-row layout: track info + timestamp on row 1, playback controls on row 2.
/// Tapping the track-info area opens the full AudioPlayerScreen.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      buildWhen: (previous, current) {
        if ((previous is AudioPlayerIdle) != (current is AudioPlayerIdle)) {
          return true;
        }
        if (previous.runtimeType != current.runtimeType) return true;
        if (previous.currentRecitation?.id != current.currentRecitation?.id) {
          return true;
        }
        if (previous is AudioPlayerReady && current is AudioPlayerReady) {
          return previous.isPlaying != current.isPlaying ||
              previous.isBuffering != current.isBuffering;
        }
        return false;
      },
      builder: (context, state) {
        if (state is AudioPlayerIdle) return const SizedBox.shrink();
        return RepaintBoundary(child: _MiniPlayerBar(state: state));
      },
    );
  }
}

class _MiniPlayerBar extends StatelessWidget {
  final AudioPlayerState state;
  const _MiniPlayerBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

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

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: border, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 90 : 20),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thin gold progress line at the very top
          _ProgressLine(gold: gold),

          SafeArea(
            top: false,
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Row 1: Track info (right) + timestamp + favorite (left) ──
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        context.push(AppRoutes.player, extra: recitation?.id),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Portrait thumbnail
                          _AvatarThumbnail(gold: gold, isDark: isDark),
                          const SizedBox(width: 10),

                          // Surah name + subtitle
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recitation?.surahNameAr ?? '',
                                  style: GoogleFonts.amiri(
                                    color: textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _subtitle(
                                    isLoading: isLoading,
                                    isBuffering: isBuffering,
                                    isError: isError,
                                    state: state,
                                  ),
                                  style: GoogleFonts.cairo(
                                    color: _subtitleColor(
                                      isLoading: isLoading,
                                      isBuffering: isBuffering,
                                      isError: isError,
                                      secondary: textSecondary,
                                      gold: gold,
                                    ),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Timestamp (live, isolated rebuild)
                          _TimestampText(
                            textSecondary: textSecondary,
                            isLoading: isLoading,
                            isError: isError,
                          ),

                          const SizedBox(width: 4),

                          // Favorite button
                          if (recitation != null)
                            BlocBuilder<FavoritesCubit, FavoritesState>(
                              builder: (context, favState) {
                                final isFav =
                                    favState.isFavorite(recitation.id);
                                return IconButton(
                                  icon: Icon(
                                    isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 19,
                                    color: isFav
                                        ? const Color(0xFFEF4444)
                                        : textSecondary.withAlpha(150),
                                  ),
                                  onPressed: () => context
                                      .read<FavoritesCubit>()
                                      .toggleFavorite(recitation.id),
                                  tooltip: isFav
                                      ? 'إزالة من المفضلة'
                                      : 'أضف إلى المفضلة',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── Row 2: Playback controls ──
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Skip backward 10s
                        _CtrlButton(
                          icon: Icons.replay_10_rounded,
                          size: 22,
                          color: isLoading || isError
                              ? textSecondary.withAlpha(80)
                              : textSecondary,
                          tooltip: 'رجوع ١٠ ثوانٍ',
                          onPressed:
                              isLoading || isError ? null : cubit.skipBackward,
                        ),

                        // Previous surah
                        _CtrlButton(
                          icon: Icons.skip_previous_rounded,
                          size: 26,
                          color: isLoading || isError
                              ? textSecondary.withAlpha(80)
                              : textSecondary,
                          tooltip: 'السورة السابقة',
                          onPressed:
                              isLoading || isError ? null : cubit.playPrevious,
                        ),

                        // Central play / pause
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

                        // Next surah
                        _CtrlButton(
                          icon: Icons.skip_next_rounded,
                          size: 26,
                          color: isLoading || isError
                              ? textSecondary.withAlpha(80)
                              : textSecondary,
                          tooltip: 'السورة التالية',
                          onPressed:
                              isLoading || isError ? null : cubit.playNext,
                        ),

                        // Skip forward 10s
                        _CtrlButton(
                          icon: Icons.forward_10_rounded,
                          size: 22,
                          color: isLoading || isError
                              ? textSecondary.withAlpha(80)
                              : textSecondary,
                          tooltip: 'تقديم ١٠ ثوانٍ',
                          onPressed:
                              isLoading || isError ? null : cubit.skipForward,
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
    );
  }

  String _subtitle({
    required bool isLoading,
    required bool isBuffering,
    required bool isError,
    required AudioPlayerState state,
  }) {
    if (isError) return (state as AudioPlayerError).message;
    if (isLoading) return 'جارٍ التحميل...';
    if (isBuffering) return 'جارٍ التخزين...';
    return 'الشيخ محمد صديق المنشاوي';
  }

  Color _subtitleColor({
    required bool isLoading,
    required bool isBuffering,
    required bool isError,
    required Color secondary,
    required Color gold,
  }) {
    if (isError) return AppColors.darkError;
    if (isLoading || isBuffering) return gold;
    return secondary;
  }
}

// ---------------------------------------------------------------------------
// Slim 2px gold progress indicator — rebuilt only on progress changes.
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// Timestamp text — rebuilt only when position / duration change (per second).
// ---------------------------------------------------------------------------
class _TimestampText extends StatelessWidget {
  final Color textSecondary;
  final bool isLoading;
  final bool isError;

  const _TimestampText({
    required this.textSecondary,
    required this.isLoading,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading || isError) return const SizedBox.shrink();

    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      buildWhen: (prev, curr) {
        if (curr is AudioPlayerReady && prev is AudioPlayerReady) {
          return prev.position.inSeconds != curr.position.inSeconds ||
              prev.duration.inSeconds != curr.duration.inSeconds;
        }
        return prev.runtimeType != curr.runtimeType;
      },
      builder: (context, state) {
        final pos =
            state is AudioPlayerReady ? state.position : Duration.zero;
        final dur =
            state is AudioPlayerReady ? state.duration : Duration.zero;
        return Text(
          '${Formatters.formatDurationObj(pos)} / ${Formatters.formatDurationObj(dur)}',
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Portrait thumbnail.
// ---------------------------------------------------------------------------
class _AvatarThumbnail extends StatelessWidget {
  final Color gold;
  final bool isDark;
  const _AvatarThumbnail({required this.gold, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: gold.withAlpha(isDark ? 110 : 80),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/minshawi_portrait.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            child: Icon(Icons.music_note_rounded, color: gold, size: 20),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Central play / pause button.
// ---------------------------------------------------------------------------
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
    final iconColor = isDark ? AppColors.darkBackground : Colors.white;
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
              ? Padding(
                  padding: const EdgeInsets.all(11),
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

// ---------------------------------------------------------------------------
// Generic control icon button with consistent touch target.
// ---------------------------------------------------------------------------
class _CtrlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  const _CtrlButton({
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