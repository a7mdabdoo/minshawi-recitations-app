import 'package:equatable/equatable.dart';

/// Identifies the section/source of a recitation.
enum RecitationType {
  murattal,
  mujawwad,
  rare,
  nahawand,
}

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

  /// Determines the [RecitationType] from [collectionId] or [id].
  RecitationType get recitationType {
    final cid = collectionId.trim().toLowerCase();
    if (cid == 'complete_murattal' ||
        cid == 'murattal' ||
        id.startsWith('murattal_')) {
      return RecitationType.murattal;
    }
    if (cid == 'mojawad' || cid == 'mujawwad' || id.startsWith('mojawad_')) {
      return RecitationType.mujawwad;
    }
    if (cid == 'nahawand' || id.startsWith('nahawand_')) {
      return RecitationType.nahawand;
    }
    return RecitationType.rare;
  }

  /// Human-readable Arabic label for the recitation source.
  String get sourceLabel {
    return switch (recitationType) {
      RecitationType.murattal => 'المصحف المرتل',
      RecitationType.mujawwad => 'المصحف المجود',
      RecitationType.rare => 'التلاوات النادرة',
      RecitationType.nahawand => 'روائع النهاوند',
    };
  }

  /// Returns `true` ONLY when [verseRange] is an actual numeric range (e.g. `1-7`, `1-286`).
  /// Returns `false` if empty or if it contains location/concert text (e.g. `مريم ليبيا`).
  bool get hasNumericVerseRange {
    final v = verseRange.trim();
    if (v.isEmpty) return false;
    return RegExp(r'^[\d\u0660-\u0669]+(\s*-\s*[\d\u0660-\u0669]+)?$')
        .hasMatch(v);
  }

  /// Returns a clean location/concert label for external or Nahawand recordings.
  String get cleanLocationLabel {
    final loc = recordingLocation.trim();
    if (loc.isNotEmpty &&
        !loc.contains('غير محدد') &&
        loc != 'تسجيل تراثي نادر') {
      final cleaned = loc.replaceAll('(', '').replaceAll(')', '').trim();
      if (cleaned.startsWith('ليبيا') ||
          cleaned.startsWith('سوريا') ||
          cleaned.startsWith('الكويت')) {
        return 'تسجيل $cleaned';
      }
      return cleaned;
    }

    // Check if surahNameAr has location after " - "
    if (surahNameAr.contains(' - ')) {
      final parts = surahNameAr.split(' - ');
      if (parts.length > 1) {
        return parts.sublist(1).join(' - ').trim();
      }
    }

    if (!hasNumericVerseRange && verseRange.trim().isNotEmpty) {
      final v = verseRange.trim();
      if (v.contains('ليبيا')) return 'تسجيل ليبيا';
      if (v.contains('دمشق')) return 'تسجيل دمشق';
      if (v.contains('الأقصى')) return 'المسجد الأقصى';
      if (v.contains('الكويت')) return 'تسجيل الكويت';
    }

    return loc.isNotEmpty ? loc : 'محفل خارجي';
  }

  /// Returns either `'الآيات: X-Y'` (when [hasNumericVerseRange] is true)
  /// or the concert/recording location without `'الآيات:'` (when false or for Nahawand concerts).
  String get trailingVerseOrLocation {
    if (recitationType == RecitationType.nahawand) {
      final loc = cleanLocationLabel;
      if (hasNumericVerseRange) {
        return loc.isNotEmpty
            ? '$loc • الآيات: ${verseRange.trim()}'
            : 'الآيات: ${verseRange.trim()}';
      }
      return loc;
    }

    if (hasNumericVerseRange) {
      return 'الآيات: ${verseRange.trim()}';
    }

    return cleanLocationLabel;
  }

  /// Builds a unified subtitle with source, duration, and either numeric verse range or location:
  /// - Standard: `المصحف المرتل • 00:51 • الآيات: 1-7`
  /// - Concert/Nahawand: `روائع النهاوند • 41:51 • تسجيل ليبيا`
  String formatSharedSubtitle(String formattedDuration) {
    final trailing = trailingVerseOrLocation.trim();
    if (trailing.isEmpty) {
      return '$sourceLabel • $formattedDuration';
    }
    return '$sourceLabel • $formattedDuration • $trailing';
  }

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
