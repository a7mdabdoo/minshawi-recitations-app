import 'package:dio/dio.dart';
import 'package:web/web.dart' as web;

import '../../features/recitations/data/datasources/local_recitation_data_source.dart';
import '../../features/recitations/domain/entities/recitation.dart';
import '../errors/exceptions.dart';

class DownloadService {
  const DownloadService({
    Dio? dio,
    LocalRecitationDataSource? localDataSource,
  });

  Future<String> download({
    required Recitation recitation,
    required void Function(double progress) onProgress,
    required CancelToken cancelToken,
  }) async {
    try {
      final fileName = '${recitation.surahNameEn.replaceAll(' ', '_')}.mp3';

      final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
      anchor.href = recitation.audioUrl;
      anchor.download = fileName;
      anchor.target = '_blank';
      anchor.rel = 'noopener noreferrer';
      anchor.style.display = 'none';

      web.document.body?.appendChild(anchor);
      anchor.click();
      web.document.body?.removeChild(anchor);

      onProgress(1.0);

      return recitation.audioUrl;
    } catch (e) {
      throw DownloadException('فشل تنزيل الملف في المتصفح: $e');
    }
  }

  Future<void> deleteDownload(String recitationId) async {}

  Future<String?> getValidLocalPath(String recitationId) async => null;

  Future<int> getPartialFileSize(Recitation recitation) async => 0;
}
