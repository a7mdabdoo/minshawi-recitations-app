import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/recitations/data/datasources/local_recitation_data_source.dart';
import '../../features/recitations/domain/entities/recitation.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

class DownloadService {
  final Dio _dio;
  final LocalRecitationDataSource _localDataSource;

  const DownloadService({
    required Dio dio,
    required LocalRecitationDataSource localDataSource,
  })  : _dio = dio,
        _localDataSource = localDataSource;

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

    if (recitation.fileSizeBytes > 0 &&
        existingLength >= recitation.fileSizeBytes) {
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
      final contentLength = contentLengthHeader != null
          ? int.tryParse(contentLengthHeader) ?? 0
          : 0;

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
        existingLength = 0;
        raf = file.openSync(mode: FileMode.write);
        totalSize =
            contentLength > 0 ? contentLength : recitation.fileSizeBytes;
      }

      if (totalSize <= 0 && recitation.fileSizeBytes > 0) {
        totalSize = recitation.fileSizeBytes;
      }

      if (totalSize > 0) {
        final initialProgress = (existingLength + receivedChunks) / totalSize;
        onProgress(initialProgress.clamp(0.0, 1.0));
      }

      final stream = response.data!.stream;
      final stopwatch = Stopwatch()..start();
      double lastReportedProgress = -1.0;
      int lastReportedMs = 0;

      await for (final chunk in stream) {
        raf.writeFromSync(chunk);
        receivedChunks += chunk.length;

        if (totalSize > 0) {
          final progress =
              ((existingLength + receivedChunks) / totalSize).clamp(0.0, 1.0);
          final elapsed = stopwatch.elapsedMilliseconds;
          if (progress >= 1.0 ||
              (progress - lastReportedProgress).abs() >= 0.01 ||
              (elapsed - lastReportedMs) >= 200) {
            lastReportedProgress = progress;
            lastReportedMs = elapsed;
            onProgress(progress);
          }
        }
      }
      stopwatch.stop();
      if (totalSize > 0 && lastReportedProgress < 1.0) {
        onProgress(1.0);
      }

      raf.flushSync();
      raf.closeSync();
      raf = null;

      if (!file.existsSync() || file.lengthSync() == 0) {
        throw const DownloadException('الملف المنزَّل فارغ أو تالف');
      }

      if (totalSize > 0 && file.lengthSync() != totalSize) {
        throw const DownloadException(
            'حجم الملف المنزَّل لا يتطابق مع الحجم المتوقع');
      }

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
        throw const DownloadPausedException();
      }

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

    try {
      final dir = await getApplicationDocumentsDirectory();
      final recitationsDir =
          Directory('${dir.path}/al_minshawi_data/${AppConstants.downloadsDirName}');
      if (recitationsDir.existsSync()) {
        final sanitizedId =
            recitationId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        for (final entity in recitationsDir.listSync()) {
          final p = entity.path;
          if (entity is File &&
              (p.contains('/$recitationId') ||
                  p.contains('\\$recitationId') ||
                  p.contains('/$sanitizedId') ||
                  p.contains('\\$sanitizedId'))) {
            if (entity.existsSync()) {
              try {
                entity.deleteSync();
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<String?> getValidLocalPath(String recitationId) async {
    final path = _localDataSource.getDownloadedPath(recitationId);
    if (path == null) return null;
    final file = File(path);
    if (file.existsSync() && file.lengthSync() > 0) return path;

    await _localDataSource.removeDownloadedPath(recitationId);
    return null;
  }

  Future<String> _buildSavePath(Recitation recitation) async {
    final dir = await getApplicationDocumentsDirectory();
    final recitationsDir =
        Directory('${dir.path}/al_minshawi_data/${AppConstants.downloadsDirName}');
    if (!await recitationsDir.exists()) {
      await recitationsDir.create(recursive: true);
    }
    final sanitizedId =
        recitation.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = '$sanitizedId.mp3';
    return '${recitationsDir.path}/$fileName';
  }
}
