import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../di/service_locator.dart';

class BatteryOptimizationService {
  BatteryOptimizationService._();

  static const MethodChannel _channel =
      MethodChannel('com.minshawi.recitations/battery_optimization');

  static const String _dismissedKey = 'battery_optimization_dialog_dismissed';

  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final bool? result =
          await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? true;
    } on PlatformException catch (_) {
      return true;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final bool? result = await _channel
          .invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> acquireLocks() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('acquireLocks');
    } catch (_) {}
  }

  static Future<void> releaseLocks() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('releaseLocks');
    } catch (_) {}
  }

  static Future<void> checkAndPromptBatteryOptimization(
      BuildContext context) async {
    if (kIsWeb || !Platform.isAndroid) return;

    final isIgnoring = await isIgnoringBatteryOptimizations();
    if (isIgnoring) return;

    try {
      if (sl.isRegistered<Box<dynamic>>(
          instanceName: AppConstants.settingsBoxName)) {
        final box =
            sl<Box<dynamic>>(instanceName: AppConstants.settingsBoxName);
        if (box.get(_dismissedKey) == true) {
          return;
        }
      }
    } catch (_) {}

    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final cardBg =
        isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: gold.withAlpha(isDark ? 90 : 60),
              width: 1.0,
            ),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: gold.withAlpha(isDark ? 35 : 20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.battery_charging_full_rounded,
                  color: gold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'استمرار التلاوة في الخلفية',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: gold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'لضمان استمرار التلاوة دون انقطاع عند قفل الشاشة، يرجى السماح للتطبيق بالعمل في الخلفية دون قيود البطارية.',
            style: GoogleFonts.cairo(
              fontSize: 13.5,
              color: textPrimary,
              height: 1.5,
            ),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                try {
                  if (sl.isRegistered<Box<dynamic>>(
                      instanceName: AppConstants.settingsBoxName)) {
                    final box = sl<Box<dynamic>>(
                        instanceName: AppConstants.settingsBoxName);
                    await box.put(_dismissedKey, true);
                  }
                } catch (_) {}
              },
              child: Text(
                'لاحقاً',
                style: GoogleFonts.cairo(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                try {
                  if (sl.isRegistered<Box<dynamic>>(
                      instanceName: AppConstants.settingsBoxName)) {
                    final box = sl<Box<dynamic>>(
                        instanceName: AppConstants.settingsBoxName);
                    await box.put(_dismissedKey, true);
                  }
                } catch (_) {}
                await requestIgnoreBatteryOptimizations();
              },
              child: Text(
                'تفعيل الآن',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
