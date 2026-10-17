import '../entities/recitation.dart';

abstract class RecitationRepository {
  Future<List<Recitation>> getRecitations({String? collectionId});

  Future<void> saveDownloadedPath({
    required String recitationId,
    required String localFilePath,
  });

  Future<void> removeDownloadedPath(String recitationId);

  String? getDownloadedPath(String recitationId);
}
