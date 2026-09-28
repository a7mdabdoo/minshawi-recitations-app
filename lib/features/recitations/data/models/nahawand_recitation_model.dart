import 'recitation_model.dart';

/// Model representing a Maqam Nahawand recitation from `assets/data/nahawand_candidates.json`.
///
/// Extends [RecitationModel] (and thus [Recitation]) so that it integrates natively
/// with [AudioPlayerCubit], [MiniPlayer], [AudioPlayerScreen], A-B Repeat,
/// background playback (`just_audio_background`), [FavoritesCubit], [PlaylistsCubit],
/// and offline downloads ([DownloadCubit]).
class NahawandRecitationModel extends RecitationModel {
  final int nahawandId;
  final int? siteId;
  final String title;
  final String surah;
  final String placeOrYear;
  final String durationFormatted;
  final String pageUrl;
  final String tag;
  final String category;
  final bool isIconicConcert;
  final bool isGoldenSelection;

  const NahawandRecitationModel({
    required super.id,
    required this.nahawandId,
    this.siteId,
    required this.title,
    required this.surah,
    required this.placeOrYear,
    required this.durationFormatted,
    required super.surahNumber,
    required super.surahNameAr,
    required super.surahNameEn,
    required super.verseRange,
    required super.durationSeconds,
    required super.fileSizeBytes,
    required super.audioUrl,
    required super.recordingYear,
    required super.recordingLocation,
    super.collectionId = 'nahawand',
    required super.isRare,
    required super.quality,
    super.localFilePath,
    this.pageUrl = '',
    this.tag = '',
    this.category = '',
    this.isIconicConcert = true,
    this.isGoldenSelection = false,
  });

  /// Parses `"MM:SS"` or `"H:MM:SS"` duration string into total seconds.
  static int parseDurationSeconds(String rawDuration) {
    final trimmed = rawDuration.trim();
    if (trimmed.isEmpty) return 0;
    final parts = trimmed.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    if (parts.length == 3) {
      return parts[0] * 3600 + parts[1] * 60 + parts[2];
    } else if (parts.length == 2) {
      return parts[0] * 60 + parts[1];
    } else if (parts.length == 1) {
      return parts[0];
    }
    return 0;
  }

  /// Builds a clear, descriptive main title for the card so tracks never just
  /// repeat the Surah name alone (e.g., `"مريم - تسجيل ليبيا 1964"`, `"يوسف - المسجد الأقصى"`).
  static String formatDisplayTitle({
    required String title,
    required String surah,
    required String placeOrYear,
  }) {
    final cleanTitle = title.trim();
    final isGenericPlace = placeOrYear.contains('غير محدد') ||
        placeOrYear.contains('تسجيل تراثي');

    // Primary surah display (if multiple surahs, keep concise)
    final surahParts = surah.split('،').map((e) => e.trim()).toList();
    final primarySurah = surahParts.length > 2
        ? '${surahParts.first} و${surahParts[1]} والقصار'
        : surahParts.join(' و');

    // Extract verse range if present in title (e.g. "1-27", "17-40", "70-87")
    final verseMatch = RegExp(r'\b(\d+\s*-\s*\d+)\b').firstMatch(cleanTitle);
    final versePart = verseMatch != null
        ? ' (${verseMatch.group(1)!.replaceAll(' ', '')})'
        : '';

    if (!isGenericPlace && placeOrYear.trim().isNotEmpty) {
      final place = placeOrYear.trim();
      final formattedPlace =
          (place.startsWith('ليبيا') || place.startsWith('سوريا') || place.startsWith('الكويت'))
              ? 'تسجيل ${place.replaceAll('(', '').replaceAll(')', '')}'
              : place.replaceAll('(', '').replaceAll(')', '');
      return '$primarySurah$versePart - $formattedPlace';
    }

    if (cleanTitle.contains(' - ')) {
      return cleanTitle;
    }

    // Fallback when place is not specified: include title details so it's unique
    return '$primarySurah - محفل تراثي ($cleanTitle)';
  }

  /// Resolves the primary Surah number (1-114) from the extracted [surah] or [category].
  static int resolveSurahNumber(String surah, String category) {
    const surahMap = <String, int>{
      'الفاتحة': 1,
      'البقرة': 2,
      'آل عمران': 3,
      'النساء': 4,
      'المائدة': 5,
      'الأنعام': 6,
      'الأعراف': 7,
      'الأنفال': 8,
      'التوبة': 9,
      'يونس': 10,
      'هود': 11,
      'يوسف': 12,
      'الرعد': 13,
      'إبراهيم': 14,
      'الحجر': 15,
      'النحل': 16,
      'الإسراء': 17,
      'الكهف': 18,
      'مريم': 19,
      'طه': 20,
      'الأنبياء': 21,
      'الحج': 22,
      'المؤمنون': 23,
      'النور': 24,
      'الفرقان': 25,
      'الشعراء': 26,
      'النمل': 27,
      'القصص': 28,
      'العنكبوت': 29,
      'الروم': 30,
      'لقمان': 31,
      'السجدة': 32,
      'الأحزاب': 33,
      'سبأ': 34,
      'فاطر': 35,
      'يس': 36,
      'الصافات': 37,
      'ص': 38,
      'الزمر': 39,
      'غافر': 40,
      'فصلت': 41,
      'الشورى': 42,
      'الزخرف': 43,
      'الدخان': 44,
      'الجاثية': 45,
      'الأحقاف': 46,
      'محمد': 47,
      'الفتح': 48,
      'الحجرات': 49,
      'ق': 50,
      'الذاريات': 51,
      'الطور': 52,
      'النجم': 53,
      'القمر': 54,
      'الرحمن': 55,
      'الواقعة': 56,
      'الحديد': 57,
      'المجادلة': 58,
      'الحشر': 59,
      'الانفطار': 82,
      'الإنفطار': 82,
      'الانشقاق': 84,
      'الإنشقاق': 84,
      'البروج': 85,
      'الطارق': 86,
      'الغاشية': 88,
      'الفجر': 89,
      'البلد': 90,
      'الشمس': 91,
      'الضحى': 93,
      'الشرح': 94,
      'العلق': 96,
      'القدر': 97,
      'القارعة': 101,
      'التكاثر': 102,
      'العصر': 103,
      'الكوثر': 108,
      'الإخلاص': 112,
    };

    if (category.contains('مريم')) return 19;
    if (category.contains('يوسف')) return 12;
    if (category.contains('سورة ق')) return 50;
    if (category.contains('الحشر')) return 59;
    if (category.contains('الروم') && surah.contains('الروم')) return 30;
    if (category.contains('الإسراء') && surah.contains('الإسراء')) return 17;
    if (category.contains('الفجر')) {
      if (surah.contains('الفجر')) return 89;
      if (surah.contains('البلد')) return 90;
    }

    final parts = surah.split('،').map((s) => s.trim());
    for (final p in parts) {
      if (surahMap.containsKey(p)) {
        return surahMap[p]!;
      }
    }
    return 19;
  }

  factory NahawandRecitationModel.fromJson(Map<String, dynamic> json) {
    final rawId = int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    final siteId = int.tryParse(json['site_id']?.toString() ?? '');
    final title = (json['title']?.toString() ?? '').trim();
    final surah = (json['surah']?.toString() ?? title).trim();
    final placeOrYear =
        (json['place_or_year']?.toString() ?? 'تسجيل تراثي نادر').trim();
    final durationFormatted = (json['duration']?.toString() ?? '0:00').trim();
    final durationSecs = parseDurationSeconds(durationFormatted);
    final audioUrl = (json['audio_url']?.toString() ?? '').trim();
    final pageUrl = (json['page_url']?.toString() ?? '').trim();
    final tag = (json['tag']?.toString() ?? '').trim();
    final category = (json['category']?.toString() ?? 'روائع النهاوند').trim();
    final isIconic = json['is_iconic_concert'] == true;
    final isGolden = json['is_golden_selection'] == true;

    final surahNum = resolveSurahNumber(surah, category);
    final displayTitle = formatDisplayTitle(
      title: title,
      surah: surah,
      placeOrYear: placeOrYear,
    );

    final numericRangeMatch =
        RegExp(r'\b(\d+\s*-\s*\d+)\b').firstMatch(title);
    final extractedNumericRange = numericRangeMatch != null
        ? numericRangeMatch.group(1)!.replaceAll(' ', '')
        : '';

    return NahawandRecitationModel(
      id: 'nahawand_$rawId',
      nahawandId: rawId,
      siteId: siteId,
      title: title,
      surah: surah,
      placeOrYear: placeOrYear,
      durationFormatted: durationFormatted,
      surahNumber: surahNum,
      surahNameAr: displayTitle,
      surahNameEn: placeOrYear,
      verseRange: extractedNumericRange,
      durationSeconds: durationSecs,
      fileSizeBytes: durationSecs > 0 ? durationSecs * 16000 : 25000000,
      audioUrl: audioUrl,
      recordingYear: placeOrYear,
      recordingLocation: placeOrYear,
      collectionId: 'nahawand',
      isRare: isGolden,
      quality: isGolden ? 'تحفة ذهبية • مقام النهاوند' : 'مقام النهاوند',
      pageUrl: pageUrl,
      tag: tag,
      category: category,
      isIconicConcert: isIconic,
      isGoldenSelection: isGolden,
    );
  }

  @override
  NahawandRecitationModel withLocalPath(String? path) {
    return NahawandRecitationModel(
      id: id,
      nahawandId: nahawandId,
      siteId: siteId,
      title: title,
      surah: surah,
      placeOrYear: placeOrYear,
      durationFormatted: durationFormatted,
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
      pageUrl: pageUrl,
      tag: tag,
      category: category,
      isIconicConcert: isIconicConcert,
      isGoldenSelection: isGoldenSelection,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        nahawandId,
        siteId,
        title,
        surah,
        placeOrYear,
        durationFormatted,
        pageUrl,
        tag,
        category,
        isIconicConcert,
        isGoldenSelection,
      ];
}
