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
    return RecitationModel(
      id: json['id'] as String,
      surahNumber: json['surahNumber'] as int,
      surahNameAr: json['surahNameAr'] as String,
      surahNameEn: json['surahNameEn'] as String,
      verseRange: json['verseRange'] as String,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      audioUrl: json['audioUrl'] as String,
      recordingYear: json['recordingYear'] as String? ?? '1387 هـ / 1967-1968',
      recordingLocation:
          json['recordingLocation'] as String? ?? 'تسجيل إذاعي (1387 هـ)',
      collectionId: json['collectionId'] as String? ?? 'rare_1387',
      isRare: json['isRare'] as bool? ?? true,
      quality: json['quality'] as String? ?? '',
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
        'isRare': isRare,
        'quality': quality,
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
