class ArabicNormalizer {
  ArabicNormalizer._();

  static final RegExp _tashkeelAndTatweelRegex =
      RegExp(r'[\u064B-\u065F\u0670\u0640\u06D6-\u06ED]');
  static final RegExp _alefVariantsRegex = RegExp(r'[أإآٱ]');
  static final RegExp _alefMaksuraRegex = RegExp(r'[ى]');
  static final RegExp _taaMarbutaRegex = RegExp(r'[ة]');

  static const Map<String, String> _arabicDigitsMap = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  static String normalize(String text) {
    if (text.isEmpty) return '';

    var normalized = text;

    normalized = normalized.replaceAll(_tashkeelAndTatweelRegex, '');

    normalized = normalized.replaceAll(_alefVariantsRegex, 'ا');

    normalized = normalized.replaceAll(_taaMarbutaRegex, 'ه');

    normalized = normalized.replaceAll(_alefMaksuraRegex, 'ي');

    _arabicDigitsMap.forEach((arabicDigit, asciiDigit) {
      normalized = normalized.replaceAll(arabicDigit, asciiDigit);
    });

    return normalized.trim().toLowerCase();
  }

  static bool matches(String source, String query) {
    if (query.trim().isEmpty) return true;
    if (source.isEmpty) return false;

    final normSource = normalize(source);
    final normQuery = normalize(query);

    if (normSource.contains(normQuery)) {
      return true;
    }

    if (normQuery.startsWith('ال') && normQuery.length > 2) {
      final strippedQuery = normQuery.substring(2);
      if (normSource.contains(strippedQuery)) {
        return true;
      }
    }

    if (normSource.startsWith('ال') && normSource.length > 2) {
      final strippedSource = normSource.substring(2);
      if (strippedSource.contains(normQuery)) {
        return true;
      }
    }

    return false;
  }

  /// Checks if all keywords in [query] match across the provided [sources].
  /// Every significant word/token in the query must be found in the normalized searchable text.
  static bool matchesMultiToken({
    required String query,
    required Iterable<String> sources,
  }) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return true;

    final combinedNormSource =
        sources.map((s) => normalize(s)).where((s) => s.isNotEmpty).join(' ');
    if (combinedNormSource.isEmpty) return false;

    final rawTokens = trimmedQuery.split(RegExp(r'\s+'));
    final tokens = rawTokens
        .map((w) => normalize(w))
        .where((w) => w.isNotEmpty)
        .toList();

    if (tokens.isEmpty) return true;

    var nonSurahTokenCount = 0;
    for (final token in tokens) {
      if (token == 'سوره' || token == 'سورة') {
        continue;
      }
      nonSurahTokenCount++;

      var matched = combinedNormSource.contains(token);

      // Check stripping "ال"
      if (!matched && token.startsWith('ال') && token.length > 2) {
        matched = combinedNormSource.contains(token.substring(2));
      }

      // Check adding "ال"
      if (!matched && !token.startsWith('ال')) {
        matched = combinedNormSource.contains('ال$token');
      }

      if (!matched) {
        return false;
      }
    }

    // If query only consisted of "سورة", match if the combined text has "سورة" or surah references
    if (nonSurahTokenCount == 0) {
      return combinedNormSource.contains('سوره') ||
          combinedNormSource.contains('سورة');
    }

    return true;
  }
}
