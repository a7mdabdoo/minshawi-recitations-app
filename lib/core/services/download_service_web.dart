import 'package:dio/dio.dart';
import 'package:web/web.dart' as web;

import '../../features/recitations/data/datasources/local_recitation_data_source.dart';
import '../../features/recitations/domain/entities/recitation.dart';
import '../errors/exceptions.dart';

/// Web implementation of [DownloadService].
///
/// On the web platform `dart:io` and `path_provider` are unavailable, so
/// this implementation delegates to the browser's native download mechanism:
/// a hidden `<a download>` anchor element is programmatically clicked,
/// causing the browser to save the MP3 directly to the user's Downloads folder.
///
/// Local file caching is **not** applicable on web — [getValidLocalPath]
/// always returns `null` and [deleteDownload] is a no-op.
///
/// This file is only compiled when [dart.library.js_interop] is available —
/// i.e. only on Flutter Web. Import via [download_service.dart].
class DownloadService {
  /// Accepts the same constructor signature as the IO version so that
  /// [service_locator.dart] requires zero platform-specific branching.
  // ignore: avoid_unused_constructor_parameters
  const DownloadService({
    Dio? dio,
    LocalRecitationDataSource? localDataSource,
  });

  /// Triggers a native browser download by creating and clicking a hidden
  /// `<a href="…" download="…">` anchor element.
  ///
  /// The browser streams the file independently; progress jumps immediately
  /// to 1.0 because the actual transfer is opaque to the Dart layer.
  ///
  /// Returns the audio URL as the "result path" (there is no local FS path).
  /// Throws [DownloadException] if the DOM manipulation fails.
  Future<String> download({
    required Recitation recitation,
    required void Function(double progress) onProgress,
    required CancelToken cancelToken,
  }) async {
    try {
      final fileName =
          '${recitation.surahNameEn.replaceAll(' ', '_')}.mp3';

      // Build an invisible anchor element with the `download` attribute,
      // which instructs the browser to save rather than navigate.
      final anchor =
          web.document.createElement('a') as web.HTMLAnchorElement;
      anchor.href = recitation.audioUrl;
      anchor.download = fileName;
      anchor.target = '_blank';
      anchor.rel = 'noopener noreferrer';
      anchor.style.display = 'none';

      // Attach → click → detach — the browser takes it from here.
      web.document.body?.appendChild(anchor);
      anchor.click();
      web.document.body?.removeChild(anchor);

      // The browser handles transfer progress; report 100 % immediately.
      onProgress(1.0);

      return recitation.audioUrl;
    } catch (e) {
      throw DownloadException('فشل تنزيل الملف في المتصفح: $e');
    }
  }

  /// No-op on web — the downloaded file lives in the OS Downloads folder
  /// and cannot be managed by the app.
  Future<void> deleteDownload(String recitationId) async {}

  /// Always returns `null` on web — the app does not cache files locally.
  Future<String?> getValidLocalPath(String recitationId) async => null;

  /// Always returns 0 on web — local file caching is not supported.
  Future<int> getPartialFileSize(Recitation recitation) async => 0;
}
