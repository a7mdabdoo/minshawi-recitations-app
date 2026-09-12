/// High-performance Arabic text normalizer utility for smart search and matching.
class ArabicNormalizer {
  ArabicNormalizer._();

  // Regex patterns for diacritics and special Arabic characters
  static final RegExp _tashkeelAndTatweelRegex =
      RegExp(r'[\u064B-\u065F\u0670\u0640\u06D6-\u06ED]');
  static final RegExp _alefVariantsRegex = RegExp(r'[أإآٱ]');
  static final RegExp _alefMaksuraRegex = RegExp(r'[ى]');
  static final RegExp _taaMarbutaRegex = RegExp(r'[ة]');

  // Arabic-Indic digits map to standard ASCII digits
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

  /// Normalizes Arabic string by removing diacritics, unifying letter variants,
  /// converting Arabic numerals to ASCII digits, and trimming whitespace.
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

  /// Returns true if [source] contains [query] after applying normalization
  /// to both strings. Also handles prefix variations like optional 'ال' (Al-).
  static bool matches(String source, String query) {
    if (query.trim().isEmpty) return true;
    if (source.isEmpty) return false;

    final normSource = normalize(source);
    final normQuery = normalize(query);

    if (normSource.contains(normQuery)) {
      return true;
    }

    // If query starts with "ال" (e.g. "الكهف"), also check without "ال" ("كهف")
    if (normQuery.startsWith('ال') && normQuery.length > 2) {
      final strippedQuery = normQuery.substring(2);
      if (normSource.contains(strippedQuery)) {
        return true;
      }
    }

    // If source starts with "ال" and query does not, check stripped source
    if (normSource.startsWith('ال') && normSource.length > 2) {
      final strippedSource = normSource.substring(2);
      if (strippedSource.contains(normQuery)) {
        return true;
      }
    }

    return false;
  }
}
