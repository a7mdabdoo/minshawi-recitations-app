import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';

/// Hive-backed store that tracks which recitations have been downloaded
/// and where their local files live.
class LocalRecitationDataSource {
  final Box<dynamic> _box;

  const LocalRecitationDataSource(this._box);

  static const String _pathPrefix = 'path_';

  /// Returns the stored local file path for [recitationId], or `null`.
  String? getDownloadedPath(String recitationId) {
    try {
      return _box.get('$_pathPrefix$recitationId') as String?;
    } catch (e) {
      return null;
    }
  }

  /// Returns a map of recitationId -> localFilePath for all downloaded files.
  Map<String, String> getAllDownloadedMap() {
    final map = <String, String>{};
    for (final key in _box.keys) {
      if (key is String && key.startsWith(_pathPrefix)) {
        final id = key.substring(_pathPrefix.length);
        final path = _box.get(key) as String?;
        if (path != null) {
          map[id] = path;
        }
      }
    }
    return map;
  }

  /// Returns a set of all downloaded recitation IDs.
  Set<String> getAllDownloadedIds() {
    return getAllDownloadedMap().keys.toSet();
  }

  /// Persists [localFilePath] for [recitationId].
  Future<void> saveDownloadedPath({
    required String recitationId,
    required String localFilePath,
  }) async {
    try {
      await _box.put('$_pathPrefix$recitationId', localFilePath);
    } catch (e) {
      throw CacheException('فشل حفظ مسار الملف المحمّل: $e');
    }
  }

  /// Removes the persisted download path for [recitationId].
  Future<void> removeDownloadedPath(String recitationId) async {
    try {
      await _box.delete('$_pathPrefix$recitationId');
    } catch (e) {
      throw CacheException('فشل حذف مسار الملف: $e');
    }
  }

  /// Convenience constructor that resolves the box from an open Hive instance.
  static LocalRecitationDataSource fromHive() {
    return LocalRecitationDataSource(
      Hive.box<dynamic>(AppConstants.downloadedFilesBoxName),
    );
  }
}
