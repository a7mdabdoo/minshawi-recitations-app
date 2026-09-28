import '../../domain/entities/recitation.dart';

/// Data-layer model that adds JSON serialisation to the [Recitation] entity.
class RecitationModel extends Recitation {
  const RecitationModel({
    required super.id,
    required super.surahNumber,
    required super.surahNameAr,
    required super.surahNameEn,
    required super.verseRange,
    required super.durationSeconds,
    required super.fileSizeBytes,
    required super.audioUrl,
    required super.recordingYear,
    required super.recordingLocation,
    super.collectionId = 'rare_1387',
    required super.isRare,
    required super.quality,
    super.localFilePath,
  });

  factory RecitationModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final rawType = json['recitationType']?.toString().trim().toLowerCase();
    String resolvedCollectionId = json['collectionId']?.toString().trim() ?? '';
    if (resolvedCollectionId.isEmpty) {
      if (rawType == 'murattal' || id.startsWith('murattal_')) {
        resolvedCollectionId = 'complete_murattal';
      } else if (rawType == 'mujawwad' || id.startsWith('mojawad_')) {
        resolvedCollectionId = 'mojawad';
      } else if (rawType == 'nahawand' || id.startsWith('nahawand_')) {
        resolvedCollectionId = 'nahawand';
      } else {
        resolvedCollectionId = 'rare_1387';
      }
    }

    return RecitationModel(
      id: id,
      surahNumber: int.tryParse(json['surahNumber']?.toString() ?? '0') ?? 0,
      surahNameAr: json['surahNameAr']?.toString() ?? '',
      surahNameEn: json['surahNameEn']?.toString() ?? '',
      verseRange: json['verseRange']?.toString() ?? '',
      durationSeconds:
          int.tryParse(json['durationSeconds']?.toString() ?? '0') ?? 0,
      fileSizeBytes:
          int.tryParse(json['fileSizeBytes']?.toString() ?? '0') ?? 0,
      audioUrl: json['audioUrl']?.toString() ?? '',
      recordingYear: json['recordingYear']?.toString() ?? '1387 هـ / 1967-1968',
      recordingLocation:
          json['recordingLocation']?.toString() ?? 'تسجيل إذاعي (1387 هـ)',
      collectionId: resolvedCollectionId,
      isRare: json['isRare'] is bool
          ? json['isRare'] as bool
          : (json['isRare']?.toString() == 'true'),
      quality: json['quality']?.toString() ?? '',
      localFilePath: json['localFilePath']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'surahNumber': surahNumber,
        'surahNameAr': surahNameAr,
        'surahNameEn': surahNameEn,
        'verseRange': verseRange,
        'durationSeconds': durationSeconds,
        'fileSizeBytes': fileSizeBytes,
        'audioUrl': audioUrl,
        'recordingYear': recordingYear,
        'recordingLocation': recordingLocation,
        'collectionId': collectionId,
        'recitationType': recitationType.name,
        'isRare': isRare,
        'quality': quality,
        if (localFilePath != null) 'localFilePath': localFilePath,
      };

  /// Produces a new [RecitationModel] with [localFilePath] injected.
  RecitationModel withLocalPath(String? path) {
    return RecitationModel(
      id: id,
      surahNumber: surahNumber,
      surahNameAr: surahNameAr,
      surahNameEn: surahNameEn,
      verseRange: verseRange,
      durationSeconds: durationSeconds,
      fileSizeBytes: fileSizeBytes,
      audioUrl: audioUrl,
      recordingYear: recordingYear,
      recordingLocation: recordingLocation,
      collectionId: collectionId,
      isRare: isRare,
      quality: quality,
      localFilePath: path,
    );
  }
}
