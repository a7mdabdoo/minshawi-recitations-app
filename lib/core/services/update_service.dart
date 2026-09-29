import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';

/// Lightweight, non-intrusive service that checks the repository's `version.json`
/// on startup and shows [UpdateDialog] if a newer version or build number exists.
class UpdateService {
  UpdateService._();

  static const String _versionJsonUrl =
      'https://raw.githubusercontent.com/a7mdabdoo/minshawi-recitations-app/main/version.json';

  static const String _defaultApkUrl =
      'https://apkpure.com/p/com.minshawi.recitations';

  static bool _hasCheckedThisSession = false;

  /// Checks for updates once per session and displays [UpdateDialog] if a newer
  /// version is available on the server. Fails silently on any network/parsing error.
  static Future<void> checkForUpdate(BuildContext context) async {
    if (_hasCheckedThisSession) return;
    _hasCheckedThisSession = true;

    try {
      final response = await http
          .get(Uri.parse(_versionJsonUrl))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return;

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return;

      final remoteVersion =
          (decoded['latest_version']?.toString() ?? '').trim();
      final remoteBuild =
          int.tryParse(decoded['build_number']?.toString() ?? '0') ?? 0;
      final releaseNotes = (decoded['release_notes']?.toString() ?? '').trim();
      final rawApkUrl =
          (decoded['apk_url']?.toString() ?? _defaultApkUrl).trim();
      final forceUpdate = decoded['force_update'] == true;

      if (remoteVersion.isEmpty) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();
      final currentBuild = int.tryParse(packageInfo.buildNumber.trim()) ?? 1;

      final isNewer = _isRemoteNewer(
        currentVersion: currentVersion,
        currentBuild: currentBuild,
        remoteVersion: remoteVersion,
        remoteBuild: remoteBuild,
      );

      if (!isNewer) return;
      if (!context.mounted) return;

      final cleanUrl = _sanitizeUrl(rawApkUrl);

      await showDialog<void>(
        context: context,
        barrierDismissible: !forceUpdate,
        builder: (ctx) => UpdateDialog(
          latestVersion: remoteVersion,
          releaseNotes: releaseNotes,
          apkUrl: cleanUrl,
          forceUpdate: forceUpdate,
        ),
      );
    } catch (_) {
      // Silently ignore offline or network/parsing errors without disturbing the user.
    }
  }

  /// Compares semantic versions (`X.Y.Z`) and `build_number`.
  static bool _isRemoteNewer({
    required String currentVersion,
    required int currentBuild,
    required String remoteVersion,
    required int remoteBuild,
  }) {
    final currParts = currentVersion
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final remParts = remoteVersion
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();

    for (var i = 0; i < 3; i++) {
      final c = i < currParts.length ? currParts[i] : 0;
      final r = i < remParts.length ? remParts[i] : 0;
      if (r > c) return true;
      if (r < c) return false;
    }

    return remoteBuild > currentBuild;
  }

  /// Extracts a clean URL even if markdown syntax `[url](url)` was accidentally used.
  static String _sanitizeUrl(String raw) {
    final trimmed = raw.trim();
    final mdMatch = RegExp(r'\((https?://[^\s\)]+)\)').firstMatch(trimmed);
    if (mdMatch != null) {
      return mdMatch.group(1)!;
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return _defaultApkUrl;
  }
}

/// Dialog notifying the user of a new app update, styled in complete harmony
/// with the app's dark navy/charcoal & gold theme.
class UpdateDialog extends StatelessWidget {
  final String latestVersion;
  final String releaseNotes;
  final String apkUrl;
  final bool forceUpdate;

  const UpdateDialog({
    super.key,
    required this.latestVersion,
    required this.releaseNotes,
    required this.apkUrl,
    this.forceUpdate = false,
  });

  Future<void> _openDownloadUrl(BuildContext context) async {
    try {
      final uri = Uri.parse(apkUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!forceUpdate && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final cardBg =
        isDark ? const Color(0xFF161B26) : AppColors.lightCardSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return PopScope(
      canPop: !forceUpdate,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: gold.withAlpha(isDark ? 95 : 70),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 150 : 40),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: gold.withAlpha(isDark ? 35 : 22),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: gold.withAlpha(80),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.system_update_rounded,
                        color: gold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'يتوفر تحديث جديد',
                            style: GoogleFonts.cairo(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: gold.withAlpha(isDark ? 30 : 20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'الإصدار $latestVersion',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: gold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black)
                          .withAlpha(isDark ? 10 : 6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: gold.withAlpha(isDark ? 45 : 30),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ما الجديد في هذا التحديث:',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: gold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          releaseNotes,
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            height: 1.55,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (!forceUpdate) ...[
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: textSecondary.withAlpha(60),
                                width: 0.8,
                              ),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'لاحقاً',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor:
                              isDark ? AppColors.darkBackground : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _openDownloadUrl(context),
                        icon: const Icon(Icons.download_rounded, size: 19),
                        label: Text(
                          'تحديث الآن',
                          style: GoogleFonts.cairo(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
