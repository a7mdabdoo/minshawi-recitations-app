import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/recitations/data/datasources/local_recitation_data_source.dart';
import '../../features/recitations/domain/entities/recitation.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// Mobile (Android / iOS) implementation of [DownloadService].
///
/// Implements manual Stream and Append logic using HTTP Range headers,
/// [FileMode.append], and chunk-by-chunk manual writing via [RandomAccessFile].
///
/// This file is only compiled when [dart.library.io] is available —
/// i.e. never on Flutter Web. Import via [download_service.dart].
class DownloadService {
  final Dio _dio;
  final LocalRecitationDataSource _localDataSource;

  const DownloadService({
    required Dio dio,
    required LocalRecitationDataSource localDataSource,
  })  : _dio = dio,
        _localDataSource = localDataSource;

  /// Returns the partially downloaded file size on disk in bytes (0 if not found).
  Future<int> getPartialFileSize(Recitation recitation) async {
    try {
      final savePath = await _buildSavePath(recitation);
      final file = File(savePath);
      if (file.existsSync()) {
        return file.lengthSync();
      }
    } catch (_) {}
    return 0;
  }

  /// Downloads or resumes downloading [recitation] to the app-documents directory.
  ///
  /// 1. Checks existing partially downloaded file size: `int existingLength = file.lengthSync();`
  /// 2. Calls `dio.get()` with `ResponseType.stream` and header `'Range': 'bytes=$existingLength-'`.
  /// 3. Opens the file strictly using [FileMode.append]: `var raf = file.openSync(mode: FileMode.append);`
  /// 4. Iterates over the incoming data stream chunk by chunk: `raf.writeFromSync(chunk);`
  /// 5. Accurately calculates progress as: `(existingLength + receivedChunks) / totalSize`
  ///
  /// Returns the absolute path of the saved file upon completion.
  /// Throws [DownloadPausedException] if paused by the user (preserving partial file).
  /// Throws [DownloadCancelledException] if cancelled by the user.
  /// Throws [DownloadException] on network or I/O failure.
  Future<String> download({
    required Recitation recitation,
    required void Function(double progress) onProgress,
    required CancelToken cancelToken,
  }) async {
    final savePath = await _buildSavePath(recitation);
    final file = File(savePath);

    int existingLength = 0;
    if (file.existsSync()) {
      existingLength = file.lengthSync();
    }

    // Check if the file is already completely downloaded
    if (recitation.fileSizeBytes > 0 && existingLength >= recitation.fileSizeBytes) {
      await _localDataSource.saveDownloadedPath(
        recitationId: recitation.id,
        localFilePath: savePath,
      );
      onProgress(1.0);
      return savePath;
    }

    final headers = <String, dynamic>{
      'Accept': 'audio/mpeg, audio/*, */*',
    };

    if (existingLength > 0) {
      headers['Range'] = 'bytes=$existingLength-';
      if (recitation.fileSizeBytes > 0) {
        onProgress((existingLength / recitation.fileSizeBytes).clamp(0.0, 1.0));
      }
    }

    RandomAccessFile? raf;
    try {
      final response = await _dio.get<ResponseBody>(
        recitation.audioUrl,
        options: Options(
          headers: headers,
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(seconds: 60),
          validateStatus: (status) =>
              status != null && (status >= 200 && status < 300),
        ),
        cancelToken: cancelToken,
      );

      final statusCode = response.statusCode ?? 200;
      final contentLengthHeader =
          response.headers.value(HttpHeaders.contentLengthHeader);
      final contentLength =
          contentLengthHeader != null ? int.tryParse(contentLengthHeader) ?? 0 : 0;

      int totalSize = 0;
      int receivedChunks = 0;

      if (statusCode == HttpStatus.partialContent) {
        raf = file.openSync(mode: FileMode.append);

        final contentRange =
            response.headers.value(HttpHeaders.contentRangeHeader);
        if (contentRange != null && contentRange.contains('/')) {
          final totalStr = contentRange.split('/').last.trim();
          totalSize =
              int.tryParse(totalStr) ?? (existingLength + contentLength);
        } else {
          totalSize = existingLength + contentLength;
        }
      } else {
        // 200 OK -> Server sent entire file from 0 (fallback or fresh download)
        existingLength = 0;
        raf = file.openSync(mode: FileMode.write);
        totalSize =
            contentLength > 0 ? contentLength : recitation.fileSizeBytes;
      }

      if (totalSize <= 0 && recitation.fileSizeBytes > 0) {
        totalSize = recitation.fileSizeBytes;
      }

      // Initial progress calculation
      if (totalSize > 0) {
        final initialProgress =
            (existingLength + receivedChunks) / totalSize;
        onProgress(initialProgress.clamp(0.0, 1.0));
      }

      final stream = response.data!.stream;
      await for (final chunk in stream) {
        raf.writeFromSync(chunk);
        receivedChunks += chunk.length;

        // Progress formula: (existingLength + receivedChunks) / totalSize
        if (totalSize > 0) {
          final progress = (existingLength + receivedChunks) / totalSize;
          onProgress(progress.clamp(0.0, 1.0));
        }
      }

      raf.flushSync();
      raf.closeSync();
      raf = null;

      // Verify file presence
      if (!file.existsSync() || file.lengthSync() == 0) {
        throw const DownloadException('الملف المنزَّل فارغ أو تالف');
      }
      // Verify file size matches expected size if known
      if (totalSize > 0 && file.lengthSync() != totalSize) {
        throw const DownloadException('حجم الملف المنزَّل لا يتطابق مع الحجم المتوقع');
      }

      // Persist path in Hive for offline playback
      await _localDataSource.saveDownloadedPath(
        recitationId: recitation.id,
        localFilePath: savePath,
      );

      return savePath;
    } on FileSystemException catch (e) {
      if (raf != null) {
        try {
          raf.flushSync();
          raf.closeSync();
        } catch (_) {}
      }

      // Detect disk full (ENOSPC: 28 on Linux/Android, ERROR_DISK_FULL: 112 on Windows)
      final isDiskFull = e.osError?.errorCode == 28 ||
          e.osError?.errorCode == 112 ||
          e.message.toLowerCase().contains('space') ||
          e.message.toLowerCase().contains('disk full');

      if (isDiskFull) {
        if (file.existsSync()) {
          try {
            file.deleteSync();
          } catch (_) {}
        }
        throw const InsufficientStorageException();
      }

      throw DownloadException('خطأ في مساحة التخزين أو الملفات: ${e.message}');
    } on DioException catch (e) {
      if (raf != null) {
        try {
          raf.flushSync();
          raf.closeSync();
        } catch (_) {}
      }

      if (e.type == DioExceptionType.cancel || CancelToken.isCancel(e)) {
        // Preserves partial file on disk without deletion
        throw const DownloadPausedException();
      }

      // Check if underlying Dio error is disk space full
      final underlying = e.error;
      final errorStr = '${e.message} ${e.error}'.toLowerCase();
      if ((underlying is FileSystemException &&
              (underlying.osError?.errorCode == 28 ||
                  underlying.osError?.errorCode == 112 ||
                  underlying.message.toLowerCase().contains('space') ||
                  underlying.message.toLowerCase().contains('disk full'))) ||
          errorStr.contains('no space left') ||
          errorStr.contains('disk full') ||
          errorStr.contains('insufficient storage')) {
        if (file.existsSync()) {
          try {
            file.deleteSync();
          } catch (_) {}
        }
        throw const InsufficientStorageException();
      }

      throw DownloadException('فشل التنزيل: ${e.message}');
    } catch (e) {
      if (raf != null) {
        try {
          raf.flushSync();
          raf.closeSync();
        } catch (_) {}
      }
      if (e is AppException) rethrow;

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('no space left') ||
          errorStr.contains('disk full') ||
          errorStr.contains('enospc') ||
          errorStr.contains('insufficient storage')) {
        if (file.existsSync()) {
          try {
            file.deleteSync();
          } catch (_) {}
        }
        throw const InsufficientStorageException();
      }

      throw DownloadException('خطأ غير متوقع أثناء التنزيل: $e');
    }
  }

  /// Deletes the locally cached file (or partial download) and removes its Hive entry.
  Future<void> deleteDownload(String recitationId) async {
    final path = _localDataSource.getDownloadedPath(recitationId);
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
      await _localDataSource.removeDownloadedPath(recitationId);
    }

    // Also remove any partial file in downloads folder
    try {
      final dir = await getApplicationDocumentsDirectory();
      final recitationsDir =
          Directory('${dir.path}/${AppConstants.downloadsDirName}');
      if (recitationsDir.existsSync()) {
        for (final entity in recitationsDir.listSync()) {
          final p = entity.path;
          if (entity is File &&
              (p.contains('/${recitationId}_') ||
                  p.contains('\\${recitationId}_'))) {
            if (entity.existsSync()) entity.deleteSync();
          }
        }
      }
    } catch (_) {}
  }

  /// Returns the local file path if the cached file exists and is non-empty.
  /// Cleans up stale Hive entries if the file was deleted outside the app.
  Future<String?> getValidLocalPath(String recitationId) async {
    final path = _localDataSource.getDownloadedPath(recitationId);
    if (path == null) return null;
    final file = File(path);
    if (file.existsSync() && file.lengthSync() > 0) return path;
    // Stale entry — clean up.
    await _localDataSource.removeDownloadedPath(recitationId);
    return null;
  }

  Future<String> _buildSavePath(Recitation recitation) async {
    final dir = await getApplicationDocumentsDirectory();
    final recitationsDir =
        Directory('${dir.path}/${AppConstants.downloadsDirName}');
    if (!await recitationsDir.exists()) {
      await recitationsDir.create(recursive: true);
    }
    final fileName =
        '${recitation.id}_${recitation.surahNameEn.replaceAll(' ', '_')}.mp3';
    return '${recitationsDir.path}/$fileName';
  }
}
