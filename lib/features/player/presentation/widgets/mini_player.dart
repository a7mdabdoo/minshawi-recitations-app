import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../favorites/presentation/cubit/favorites_state.dart';
import '../../../recitations/domain/entities/recitation.dart';
import '../cubit/audio_player_cubit.dart';
import '../cubit/audio_player_state.dart';
import '../pages/audio_player_screen.dart';

/// Persistent bottom mini-player bar shown whenever a track is active.
///
/// Features:
///   - Top 2px gold progress line.
///   - Top subtle drag handle indicator (36x3.5 dp).
///   - Tap anywhere & swipe-up gesture to smoothly open [AudioPlayerScreen]
///     via a bottom-to-top slide transition (PageRouteBuilder).
///   - Row 1 (Track Info & Actions):
///       * Right: Surah name (bold Arabic) + expand arrow, with Quranic metadata
///         tag (revelation type & ayah count, e.g. "مدنية • ٢٨٦ آية") below it.
///       * Left: Favorite (heart) and Close (dismiss) buttons with clear padding.
///   - Seek Bar Row: Interactive seek slider with elapsed & total duration.
///   - Row 2 (Playback Controls): Previous, Replay 10s (-10), Play/Pause (prominent gold circle), Forward 10s (+10), Next.
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

// ==========================================================
// Main content shell with gesture recognition & slide-up animation
// ==========================================================
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
    final bg = isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
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
          border: Border(top: BorderSide(color: borderColor, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 110 : 25),
              blurRadius: 18,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 1. Top 2px gold progress line ─────────────────
            _ProgressLine(gold: gold),

            // ── 2. Visual Drag Handle Indicator ────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 5, bottom: 2),
                width: 36,
                height: 3.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            SafeArea(
              top: false,
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── 3. Row 1: Surah Title + Metadata (Right) & Actions (Left) ──
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Right side (RTL start): Surah name + Metadata tag
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        recitation?.surahNameAr ?? '',
                                        style: GoogleFonts.amiri(
                                          color: textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_up_rounded,
                                      size: 18,
                                      color: gold.withAlpha(220),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _getSurahMetaTag(recitation),
                                  style: GoogleFonts.cairo(
                                    color: isDark
                                        ? Colors.white54
                                        : textSecondary,
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

                          // Left side (RTL end): Favorite + Close buttons
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 1. Favorite button
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
                                          : (isDark
                                              ? Colors.white60
                                              : textSecondary.withAlpha(160)),
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

                              // 2. Close / Dismiss button (stops playback & hides bar)
                              _IconTap(
                                icon: Icons.close_rounded,
                                size: 20,
                                color: isDark
                                    ? Colors.white60
                                    : textSecondary.withAlpha(180),
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

                    const SizedBox(height: 6),

                    // ── 4. Interactive seek-bar + timestamps ────────
                    _SeekBarRow(
                      gold: gold,
                      isDark: isDark,
                      isLoading: isLoading,
                      isError: isError,
                      textSecondary: textSecondary,
                      cubit: cubit,
                    ),

                    const SizedBox(height: 4),

                    // ── 5. Row 2: Playback Controls (Centered & Spaced) ──
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

                          // Left side of Play button: Seek backward 10s (-10)
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

                          // Prominent Gold Play/Pause Button
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

                          // Right side of Play button: Seek forward 10s (+10)
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

  /// Formats Quranic metadata: revelation type and ayah count (e.g. "مدنية • ٢٨٦ آية")
  String _getSurahMetaTag(Recitation? recitation) {
    if (recitation == null) return '';
    final surahNum = recitation.surahNumber;
    final meta = _surahData[surahNum];
    if (meta == null) {
      return 'فضيلة الشيخ محمد صديق المنشاوي';
    }
    final type = meta.isMeccan ? 'مكية' : 'مدنية';
    final countStr = _toArabicDigits(meta.verses);
    final ayahWord = (meta.verses >= 3 && meta.verses <= 10) ? 'آيات' : 'آية';

    if (recitation.verseRange.isNotEmpty &&
        recitation.verseRange != '1-${meta.verses}' &&
        recitation.verseRange != '1 - ${meta.verses}') {
      return '$type • الآيات: ${recitation.verseRange}';
    }
    return '$type • $countStr $ayahWord';
  }

  static String _toArabicDigits(int number) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((c) {
      final idx = int.tryParse(c);
      return idx != null ? digits[idx] : c;
    }).join();
  }
}

// ==========================================================
// Surah Metadata definition and lookup table for all 114 Surahs
// ==========================================================
class _SurahInfo {
  final bool isMeccan;
  final int verses;
  const _SurahInfo(this.isMeccan, this.verses);
}

const Map<int, _SurahInfo> _surahData = {
  1: _SurahInfo(true, 7),
  2: _SurahInfo(false, 286),
  3: _SurahInfo(false, 200),
  4: _SurahInfo(false, 176),
  5: _SurahInfo(false, 120),
  6: _SurahInfo(true, 165),
  7: _SurahInfo(true, 206),
  8: _SurahInfo(false, 75),
  9: _SurahInfo(false, 129),
  10: _SurahInfo(true, 109),
  11: _SurahInfo(true, 123),
  12: _SurahInfo(true, 111),
  13: _SurahInfo(false, 43),
  14: _SurahInfo(true, 52),
  15: _SurahInfo(true, 99),
  16: _SurahInfo(true, 128),
  17: _SurahInfo(true, 111),
  18: _SurahInfo(true, 110),
  19: _SurahInfo(true, 98),
  20: _SurahInfo(true, 135),
  21: _SurahInfo(true, 112),
  22: _SurahInfo(false, 78),
  23: _SurahInfo(true, 118),
  24: _SurahInfo(false, 64),
  25: _SurahInfo(true, 77),
  26: _SurahInfo(true, 227),
  27: _SurahInfo(true, 93),
  28: _SurahInfo(true, 88),
  29: _SurahInfo(true, 69),
  30: _SurahInfo(true, 60),
  31: _SurahInfo(true, 34),
  32: _SurahInfo(true, 30),
  33: _SurahInfo(false, 73),
  34: _SurahInfo(true, 54),
  35: _SurahInfo(true, 45),
  36: _SurahInfo(true, 83),
  37: _SurahInfo(true, 182),
  38: _SurahInfo(true, 88),
  39: _SurahInfo(true, 75),
  40: _SurahInfo(true, 85),
  41: _SurahInfo(true, 54),
  42: _SurahInfo(true, 53),
  43: _SurahInfo(true, 89),
  44: _SurahInfo(true, 59),
  45: _SurahInfo(true, 37),
  46: _SurahInfo(true, 35),
  47: _SurahInfo(false, 38),
  48: _SurahInfo(false, 29),
  49: _SurahInfo(false, 18),
  50: _SurahInfo(true, 45),
  51: _SurahInfo(true, 60),
  52: _SurahInfo(true, 49),
  53: _SurahInfo(true, 62),
  54: _SurahInfo(true, 55),
  55: _SurahInfo(false, 78),
  56: _SurahInfo(true, 96),
  57: _SurahInfo(false, 29),
  58: _SurahInfo(false, 22),
  59: _SurahInfo(false, 24),
  60: _SurahInfo(false, 13),
  61: _SurahInfo(false, 14),
  62: _SurahInfo(false, 11),
  63: _SurahInfo(false, 11),
  64: _SurahInfo(false, 18),
  65: _SurahInfo(false, 12),
  66: _SurahInfo(false, 12),
  67: _SurahInfo(true, 30),
  68: _SurahInfo(true, 52),
  69: _SurahInfo(true, 52),
  70: _SurahInfo(true, 44),
  71: _SurahInfo(true, 28),
  72: _SurahInfo(true, 28),
  73: _SurahInfo(true, 20),
  74: _SurahInfo(true, 56),
  75: _SurahInfo(true, 40),
  76: _SurahInfo(false, 31),
  77: _SurahInfo(true, 50),
  78: _SurahInfo(true, 40),
  79: _SurahInfo(true, 46),
  80: _SurahInfo(true, 42),
  81: _SurahInfo(true, 29),
  82: _SurahInfo(true, 19),
  83: _SurahInfo(true, 36),
  84: _SurahInfo(true, 25),
  85: _SurahInfo(true, 22),
  86: _SurahInfo(true, 17),
  87: _SurahInfo(true, 19),
  88: _SurahInfo(true, 26),
  89: _SurahInfo(true, 30),
  90: _SurahInfo(true, 20),
  91: _SurahInfo(true, 15),
  92: _SurahInfo(true, 21),
  93: _SurahInfo(true, 11),
  94: _SurahInfo(true, 8),
  95: _SurahInfo(true, 8),
  96: _SurahInfo(true, 19),
  97: _SurahInfo(true, 5),
  98: _SurahInfo(false, 8),
  99: _SurahInfo(false, 8),
  100: _SurahInfo(true, 11),
  101: _SurahInfo(true, 11),
  102: _SurahInfo(true, 8),
  103: _SurahInfo(true, 3),
  104: _SurahInfo(true, 9),
  105: _SurahInfo(true, 5),
  106: _SurahInfo(true, 4),
  107: _SurahInfo(true, 7),
  108: _SurahInfo(true, 3),
  109: _SurahInfo(true, 6),
  110: _SurahInfo(false, 3),
  111: _SurahInfo(true, 5),
  112: _SurahInfo(true, 4),
  113: _SurahInfo(true, 5),
  114: _SurahInfo(true, 6),
};

// ==========================================================
// Passive 2px progress line (rebuilt only on progress change)
// ==========================================================
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

// ==========================================================
// Interactive seek-bar with elapsed / total timestamps
// ==========================================================
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

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Slider / indeterminate bar
            SizedBox(
              height: 20,
              child: widget.isLoading || widget.isError
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(
                        value: widget.isLoading ? null : 0,
                        minHeight: 2.5,
                        backgroundColor: widget.isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(widget.gold),
                      ),
                    )
                  : SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2.5,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                          disabledThumbRadius: 0,
                        ),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: widget.gold,
                        inactiveTrackColor: widget.isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
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

            // Timestamps
            if (!widget.isLoading && !widget.isError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Formatters.formatDurationObj(position),
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: widget.textSecondary,
                      ),
                    ),
                    Text(
                      Formatters.formatDurationObj(duration),
                      style: GoogleFonts.cairo(
                        fontSize: 10,
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

// ==========================================================
// Central gold play / pause button
// ==========================================================
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

// ==========================================================
// Generic tappable icon (32dp minimum touch area)
// ==========================================================
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

// ==========================================================
// Playback control button (skip / prev / next)
// ==========================================================
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
