import '../entities/recitation.dart';

/// Contract that both local and remote data sources must satisfy.
abstract class RecitationRepository {
  /// Loads recitations from the bundled asset manifest and merges
  /// any locally downloaded file paths stored in Hive.
  /// If [collectionId] is provided, only recitations for that collection are loaded.
  Future<List<Recitation>> getRecitations({String? collectionId});

  /// Persists [localFilePath] for [recitationId] in Hive.
  Future<void> saveDownloadedPath({
    required String recitationId,
    required String localFilePath,
  });

  /// Removes the persisted download path for [recitationId] from Hive.
  Future<void> removeDownloadedPath(String recitationId);

  /// Returns the stored local file path for [recitationId], or `null`.
  String? getDownloadedPath(String recitationId);
}
