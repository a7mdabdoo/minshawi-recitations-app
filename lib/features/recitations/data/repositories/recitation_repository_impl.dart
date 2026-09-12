import 'dart:io';

import '../../domain/entities/recitation.dart';
import '../../domain/repositories/recitation_repository.dart';
import '../datasources/local_recitation_data_source.dart';
import '../datasources/manifest_data_source.dart';

/// Concrete implementation of [RecitationRepository].
///
/// Strategy:
/// 1. Load models from the bundled JSON asset via [ManifestDataSource].
/// 2. For each model, check [LocalRecitationDataSource] for a stored download path.
/// 3. Merge the path into the model so the domain entity reflects offline availability.
class RecitationRepositoryImpl implements RecitationRepository {
  final ManifestDataSource _manifestDataSource;
  final LocalRecitationDataSource _localDataSource;

  const RecitationRepositoryImpl({
    required ManifestDataSource manifestDataSource,
    required LocalRecitationDataSource localDataSource,
  }) : _manifestDataSource = manifestDataSource,
       _localDataSource = localDataSource;

  @override
  Future<List<Recitation>> getRecitations({String? collectionId}) async {
    // Throws CacheException or ParseException on failure — propagated up.
    final models =
        await _manifestDataSource.loadManifest(collectionId: collectionId);

    // Merge any stored download paths (validating file existence on disk).
    return models.map((model) {
      final path = _localDataSource.getDownloadedPath(model.id);
      if (path != null) {
        final file = File(path);
        if (file.existsSync() && file.lengthSync() > 0) {
          return model.withLocalPath(path);
        } else {
          // File was deleted or is 0-byte corrupt — clean stale Hive entry.
          _localDataSource.removeDownloadedPath(model.id);
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
