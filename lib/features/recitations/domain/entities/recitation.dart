import 'package:equatable/equatable.dart';

/// Pure domain entity — no JSON, no Hive, no Flutter imports.
class Recitation extends Equatable {
  final String id;
  final int surahNumber;
  final String surahNameAr;
  final String surahNameEn;
  final String verseRange;
  final int durationSeconds;
  final int fileSizeBytes;
  final String audioUrl;
  final String recordingYear;
  final String recordingLocation;
  final String collectionId;
  final bool isRare;
  final String quality;

  /// Absolute path to the locally downloaded file.
  /// `null` means the recitation has not been downloaded yet.
  final String? localFilePath;

  const Recitation({
    required this.id,
    required this.surahNumber,
    required this.surahNameAr,
    required this.surahNameEn,
    required this.verseRange,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.audioUrl,
    required this.recordingYear,
    required this.recordingLocation,
    this.collectionId = 'rare_1387',
    required this.isRare,
    required this.quality,
    this.localFilePath,
  });

  bool get isDownloaded => localFilePath != null;

  /// Returns the effective playback URI: local file if downloaded, else stream URL.
  String get playbackUri => localFilePath ?? audioUrl;

  Recitation copyWith({
    String? id,
    int? surahNumber,
    String? surahNameAr,
    String? surahNameEn,
    String? verseRange,
    int? durationSeconds,
    int? fileSizeBytes,
    String? audioUrl,
    String? recordingYear,
    String? recordingLocation,
    String? collectionId,
    bool? isRare,
    String? quality,
    String? localFilePath,
    bool clearLocalFilePath = false,
  }) {
    return Recitation(
      id: id ?? this.id,
      surahNumber: surahNumber ?? this.surahNumber,
      surahNameAr: surahNameAr ?? this.surahNameAr,
      surahNameEn: surahNameEn ?? this.surahNameEn,
      verseRange: verseRange ?? this.verseRange,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      audioUrl: audioUrl ?? this.audioUrl,
      recordingYear: recordingYear ?? this.recordingYear,
      recordingLocation: recordingLocation ?? this.recordingLocation,
      collectionId: collectionId ?? this.collectionId,
      isRare: isRare ?? this.isRare,
      quality: quality ?? this.quality,
      localFilePath:
          clearLocalFilePath ? null : (localFilePath ?? this.localFilePath),
    );
  }

  @override
  List<Object?> get props => [
        id,
        surahNumber,
        surahNameAr,
        surahNameEn,
        verseRange,
        durationSeconds,
        fileSizeBytes,
        audioUrl,
        recordingYear,
        recordingLocation,
        collectionId,
        isRare,
        quality,
        localFilePath,
      ];
}
