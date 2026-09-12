import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../cubit/sleep_timer_cubit.dart';
import '../cubit/sleep_timer_state.dart';

/// Displays an ultra-compact, minimalist Sleep Timer bottom sheet.
Future<void> showSleepTimerBottomSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: false,
    builder: (modalContext) => const _SleepTimerBottomSheetContent(),
  );
}

class _SleepTimerBottomSheetContent extends StatelessWidget {
  const _SleepTimerBottomSheetContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final bgColor = isDark ? const Color(0xFF141C26) : Colors.white;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16.0 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: gold.withValues(alpha: isDark ? 0.35 : 0.4),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BlocBuilder<SleepTimerCubit, SleepTimerState>(
        builder: (context, state) {
          final isActive = state.isActive;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Icon(
                    Icons.bedtime_rounded,
                    color: gold,
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'مؤقت النوم',
                    style: GoogleFonts.amiri(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: gold,
                      height: 1.1,
                    ),
                  ),

                  const Spacer(),

                  // If active: show live countdown badge + cancel button
                  if (isActive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: gold.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.mode == SleepTimerMode.duration)
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                Formatters.formatDuration(
                                    state.remainingTime?.inSeconds ?? 0),
                                style: GoogleFonts.cairo(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: gold,
                                ),
                              ),
                            )
                          else
                            Text(
                              'نهاية السورة',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: gold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        context.read<SleepTimerCubit>().cancelTimer();
                        _showFeedback(context, 'تم إلغاء مؤقت النوم');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Text(
                          'إلغاء',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],

                  // Close Button
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _CompactTimerChip(
                    label: '١٥ دقيقة',
                    isSelected: state.selectedOptionLabel == '١٥ دقيقة',
                    gold: gold,
                    isDark: isDark,
                    onTap: () {
                      context
                          .read<SleepTimerCubit>()
                          .startTimer(const Duration(minutes: 15), '١٥ دقيقة');
                      Navigator.pop(context);
                      _showFeedback(context, 'تم ضبط مؤقت النوم على ١٥ دقيقة');
                    },
                  ),
                  _CompactTimerChip(
                    label: '٣٠ دقيقة',
                    isSelected: state.selectedOptionLabel == '٣٠ دقيقة',
                    gold: gold,
                    isDark: isDark,
                    onTap: () {
                      context
                          .read<SleepTimerCubit>()
                          .startTimer(const Duration(minutes: 30), '٣٠ دقيقة');
                      Navigator.pop(context);
                      _showFeedback(context, 'تم ضبط مؤقت النوم على ٣٠ دقيقة');
                    },
                  ),
                  _CompactTimerChip(
                    label: '٤٥ دقيقة',
                    isSelected: state.selectedOptionLabel == '٤٥ دقيقة',
                    gold: gold,
                    isDark: isDark,
                    onTap: () {
                      context
                          .read<SleepTimerCubit>()
                          .startTimer(const Duration(minutes: 45), '٤٥ دقيقة');
                      Navigator.pop(context);
                      _showFeedback(context, 'تم ضبط مؤقت النوم على ٤٥ دقيقة');
                    },
                  ),
                  _CompactTimerChip(
                    label: '٦٠ دقيقة',
                    isSelected: state.selectedOptionLabel == '٦٠ دقيقة' ||
                        state.selectedOptionLabel == 'ساعة كاملة',
                    gold: gold,
                    isDark: isDark,
                    onTap: () {
                      context
                          .read<SleepTimerCubit>()
                          .startTimer(const Duration(minutes: 60), '٦٠ دقيقة');
                      Navigator.pop(context);
                      _showFeedback(context, 'تم ضبط مؤقت النوم على ٦٠ دقيقة');
                    },
                  ),
                  _CompactTimerChip(
                    label: 'نهاية السورة',
                    isSelected: state.selectedOptionLabel == 'نهاية السورة' ||
                        state.selectedOptionLabel == 'عند نهاية السورة',
                    gold: gold,
                    isDark: isDark,
                    onTap: () {
                      context
                          .read<SleepTimerCubit>()
                          .setTimerEndOfSurah(label: 'نهاية السورة');
                      Navigator.pop(context);
                      _showFeedback(
                          context, 'تم ضبط مؤقت النوم للإيقاف عند نهاية السورة');
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.bedtime_rounded,
                color: AppColors.goldPrimary, size: 18),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _CompactTimerChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color gold;
  final bool isDark;
  final VoidCallback onTap;

  const _CompactTimerChip({
    required this.label,
    required this.isSelected,
    required this.gold,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipBg = isSelected
        ? gold.withValues(alpha: isDark ? 0.18 : 0.12)
        : (isDark ? const Color(0xFF1C2633) : const Color(0xFFF1F5F9));

    final chipBorder = isSelected
        ? Border.all(color: gold, width: 1.2)
        : Border.all(
            color: (isDark ? Colors.white10 : Colors.black12),
            width: 0.8,
          );

    final chipTextColor = isSelected
        ? gold
        : (isDark ? Colors.white70 : const Color(0xFF334155));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: gold.withValues(alpha: 0.15),
        highlightColor: gold.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(12),
            border: chipBorder,
          ),
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: chipTextColor,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
