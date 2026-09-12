import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../favorites/presentation/cubit/favorites_state.dart';
import '../cubit/audio_player_cubit.dart';
import '../cubit/audio_player_state.dart';

/// Minimal persistent mini-player that appears at the bottom of the screen
/// when a track is active. Tap anywhere to open the full player.
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
              previous.isBuffering != current.isBuffering ||
              previous.progress != current.progress;
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
    final progress =
        state is AudioPlayerReady ? (state as AudioPlayerReady).progress : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(AppRoutes.player, extra: recitation?.id),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 90 : 25),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 2px gold progress indicator at the very top edge
            _ProgressLine(progress: progress, gold: gold),

            SafeArea(
              top: false,
              bottom: true,
              child: SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Leading: rounded portrait thumbnail
                        _AvatarThumbnail(gold: gold, isDark: isDark),
                        const SizedBox(width: 12),

                        // Center: Surah name + status subtitle
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recitation?.surahNameAr
                                        .replaceAll('ط³ظˆط±ط©', '')
                                        .trim() ??
                                    '',
                                style: GoogleFonts.amiri(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _subtitleLabel(
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
                                    textSecondary: textSecondary,
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

                        // Trailing: favorite + play/pause
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                                      size: 20,
                                      color: isFav
                                          ? const Color(0xFFEF4444)
                                          : textSecondary.withAlpha(160),
                                    ),
                                    onPressed: () => context
                                        .read<FavoritesCubit>()
                                        .toggleFavorite(recitation.id),
                                    tooltip: isFav
                                        ? 'ط¥ط²ط§ظ„ط© ظ…ظ† ط§ظ„ظ…ظپط¶ظ„ط©'
                                        : 'ط£ط¶ظپ ط¥ظ„ظ‰ ط§ظ„ظ…ظپط¶ظ„ط©',
                                    padding: const EdgeInsets.all(6),
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  );
                                },
                              ),

                            const SizedBox(width: 4),

                            _MiniPlayPauseButton(
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitleLabel({
    required bool isLoading,
    required bool isBuffering,
    required bool isError,
    required AudioPlayerState state,
  }) {
    if (isError) return (state as AudioPlayerError).message;
    if (isLoading) return 'ط¬ط§ط±ظچ ط§ظ„طھط­ظ…ظٹظ„...';
    if (isBuffering) return 'ط¬ط§ط±ظچ ط§ظ„طھط®ط²ظٹظ†...';
    return 'ط§ظ„ط´ظٹط® ظ…ط­ظ…ط¯ طµط¯ظٹظ‚ ط§ظ„ظ…ظ†ط´ط§ظˆظٹ';
  }

  Color _subtitleColor({
    required bool isLoading,
    required bool isBuffering,
    required bool isError,
    required Color textSecondary,
    required Color gold,
  }) {
    if (isError) return AppColors.darkError;
    if (isLoading || isBuffering) return gold;
    return textSecondary;
  }
}

/// Slim 2px gold linear progress bar at the very top of the mini-player.
class _ProgressLine extends StatelessWidget {
  final double progress;
  final Color gold;

  const _ProgressLine({required this.progress, required this.gold});

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
        final liveProgress =
            state is AudioPlayerReady ? state.progress : progress;

        return LinearProgressIndicator(
          value: isLoading ? null : liveProgress.clamp(0.0, 1.0),
          minHeight: 2,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(gold),
        );
      },
    );
  }
}

/// Small 44أ—44 rounded square showing the Sheikh's portrait or a music icon.
class _AvatarThumbnail extends StatelessWidget {
  final Color gold;
  final bool isDark;
  const _AvatarThumbnail({required this.gold, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: gold.withAlpha(isDark ? 120 : 90),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.asset(
          'assets/images/minshawi_portrait.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color:
                isDark ? AppColors.darkBackground : AppColors.lightBackground,
            child: Icon(Icons.music_note_rounded, color: gold, size: 22),
          ),
        ),
      ),
    );
  }
}

/// Gold circular play/pause button with comfortable 44dp tap target.
class _MiniPlayPauseButton extends StatelessWidget {
  final bool isLoading;
  final bool isBuffering;
  final bool isPlaying;
  final bool isError;
  final Color gold;
  final bool isDark;
  final VoidCallback? onTap;

  const _MiniPlayPauseButton({
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
          width: 44,
          height: 44,
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
                  padding: const EdgeInsets.all(12),
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
                    size: 26,
                  ),
                ),
        ),
      ),
    );
  }
}
