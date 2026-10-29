import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';

class UpdateService {
  UpdateService._();

  static const String _versionJsonUrl =
      'https://raw.githubusercontent.com/a7mdabdoo/minshawi-recitations-app/main/version.json';

  static const String _defaultApkUrl =
      'https://github.com/a7mdabdoo/minshawi-recitations-app/releases/download/v1.2.1/al-minshawi-recitations-v1.2.1.apk';

  static const String _defaultWindowsUrl =
      'https://github.com/a7mdabdoo/minshawi-recitations-app/releases/latest';

  static bool _hasCheckedThisSession = false;

  static Future<void> checkForUpdate(BuildContext context) async {
    if (kIsWeb) return;
    if (_hasCheckedThisSession) return;
    _hasCheckedThisSession = true;

    try {
      final response = await http
          .get(Uri.parse(_versionJsonUrl))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return;

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return;

      Map<String, dynamic>? platformConfig;
      String fallbackUrl = _defaultApkUrl;

      if (Platform.isAndroid) {
        if (decoded['android'] is Map<String, dynamic>) {
          platformConfig = decoded['android'] as Map<String, dynamic>;
        }
        fallbackUrl = _defaultApkUrl;
      } else if (Platform.isWindows) {
        if (decoded['windows'] is Map<String, dynamic>) {
          platformConfig = decoded['windows'] as Map<String, dynamic>;
        }
        fallbackUrl = _defaultWindowsUrl;
      } else if (Platform.isIOS) {
        if (decoded['ios'] is Map<String, dynamic>) {
          platformConfig = decoded['ios'] as Map<String, dynamic>;
        }
      }

      final targetData = platformConfig ?? decoded;

      final remoteVersion =
          (targetData['latest_version']?.toString() ?? '').trim();
      final remoteBuild =
          int.tryParse(targetData['build_number']?.toString() ?? '0') ?? 0;
      final releaseNotes =
          (targetData['release_notes']?.toString() ?? '').trim();
      final rawDownloadUrl = (targetData['download_url']?.toString() ??
              targetData['apk_url']?.toString() ??
              fallbackUrl)
          .trim();
      final forceUpdate = targetData['force_update'] == true;

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

      final cleanUrl = _sanitizeUrl(rawDownloadUrl, fallback: fallbackUrl);

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
    } catch (_) {}
  }

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

  static String _sanitizeUrl(String raw, {String fallback = _defaultApkUrl}) {
    final trimmed = raw.trim();
    final mdMatch = RegExp(r'\((https?://[^\s\)]+)\)').firstMatch(trimmed);
    if (mdMatch != null) {
      return mdMatch.group(1)!;
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return fallback;
  }
}

class UpdateDialog extends StatefulWidget {
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

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusText = '';
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _startUpdate() async {
    final isApk = widget.apkUrl.toLowerCase().contains('.apk');

    if (Platform.isAndroid && isApk) {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
        _statusText = 'جاري بدء التحميل...';
      });

      _cancelToken = CancelToken();

      try {
        final tempDir = await getTemporaryDirectory();
        final savePath =
            '${tempDir.path}/minshawi_update_${widget.latestVersion}.apk';

        final dio = Dio(
          BaseOptions(
            followRedirects: true,
            maxRedirects: 5,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(minutes: 10),
          ),
        );
        await dio.download(
          widget.apkUrl,
          savePath,
          deleteOnError: true,
          cancelToken: _cancelToken,
          onReceiveProgress: (received, total) {
            if (total > 0 && mounted) {
              setState(() {
                _downloadProgress = (received / total).clamp(0.0, 1.0);
                final pct = (_downloadProgress * 100).toInt();
                final mbReceived =
                    (received / (1024 * 1024)).toStringAsFixed(1);
                final mbTotal = (total / (1024 * 1024)).toStringAsFixed(1);
                _statusText =
                    'جاري التنزيل: $mbReceived / $mbTotal ميجابايت ($pct%)';
              });
            }
          },
        );

        if (mounted) {
          setState(() {
            _statusText = 'اكتمل التنزيل، جاري فتح مثبت الحزم...';
          });
        }

        final result = await OpenFilex.open(
          savePath,
          type: 'application/vnd.android.package-archive',
        );

        if (result.type != ResultType.done && mounted) {
          await _fallbackExternalOpen();
        }
      } catch (e) {
        if (mounted && _cancelToken?.isCancelled != true) {
          setState(() {
            _isDownloading = false;
            _statusText = 'تعذّر التنزيل المباشر، جاري الفتح في المتصفح...';
          });
          await _fallbackExternalOpen();
        }
      }
    } else {
      await _fallbackExternalOpen();
    }
  }

  Future<void> _fallbackExternalOpen() async {
    try {
      final uri = Uri.parse(widget.apkUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!widget.forceUpdate && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
      _statusText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? AppColors.goldPrimary : AppColors.goldDark;
    final cardBg =
        isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return PopScope(
      canPop: !widget.forceUpdate && !_isDownloading,
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
                              'الإصدار ${widget.latestVersion}',
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
                if (widget.releaseNotes.isNotEmpty) ...[
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
                          widget.releaseNotes,
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
                if (_isDownloading) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value:
                              _downloadProgress > 0 ? _downloadProgress : null,
                          minHeight: 8,
                          backgroundColor:
                              (isDark ? Colors.white12 : Colors.black12),
                          valueColor: AlwaysStoppedAnimation<Color>(gold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _statusText,
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!widget.forceUpdate)
                            GestureDetector(
                              onTap: _cancelDownload,
                              child: Text(
                                'إلغاء',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkError,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      if (!widget.forceUpdate) ...[
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
                            foregroundColor: isDark
                                ? AppColors.darkBackground
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _startUpdate,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
