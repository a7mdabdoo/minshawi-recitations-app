import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../domain/entities/recitation.dart';
import '../../domain/repositories/recitation_repository.dart';
import '../datasources/local_recitation_data_source.dart';
import '../datasources/manifest_data_source.dart';

class RecitationRepositoryImpl implements RecitationRepository {
  final ManifestDataSource _manifestDataSource;
  final LocalRecitationDataSource _localDataSource;

  const RecitationRepositoryImpl({
    required ManifestDataSource manifestDataSource,
    required LocalRecitationDataSource localDataSource,
  })  : _manifestDataSource = manifestDataSource,
        _localDataSource = localDataSource;

  @override
  Future<List<Recitation>> getRecitations({String? collectionId}) async {
    final models =
        await _manifestDataSource.loadManifest(collectionId: collectionId);

    return models.map((model) {
      final path = _localDataSource.getDownloadedPath(model.id);
      if (path != null) {
        if (!kIsWeb) {
          try {
            final file = File(path);
            if (file.existsSync() && file.lengthSync() > 0) {
              return model.withLocalPath(path);
            }
          } catch (_) {}
        } else {
          return model.withLocalPath(path);
        }
      }
      return model.withLocalPath(null);
    }).toList();
  }

  @override
  Future<void> saveDownloadedPath({
    required String recitationId,
    required String localFilePath,
  }) {
    return _localDataSource.saveDownloadedPath(
      recitationId: recitationId,
      localFilePath: localFilePath,
    );
  }

  @override
  Future<void> removeDownloadedPath(String recitationId) {
    return _localDataSource.removeDownloadedPath(recitationId);
  }

  @override
  String? getDownloadedPath(String recitationId) {
    return _localDataSource.getDownloadedPath(recitationId);
  }
}
