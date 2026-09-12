/// Formatting utilities for durations and file sizes.
abstract class Formatters {
  Formatters._();

  /// Converts [totalSeconds] to `mm:ss` or `h:mm:ss` format.
  static String formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Converts a [Duration] to `mm:ss` or `h:mm:ss` format.
  static String formatDurationObj(Duration duration) {
    return formatDuration(duration.inSeconds);
  }

  /// Converts [bytes] into a human-readable file size string (KB / MB / GB).
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 KB';

    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;

    if (bytes >= gb) {
      final val = bytes / gb;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} GB';
    }
    if (bytes >= mb) {
      final val = bytes / mb;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} MB';
    }
    if (bytes >= kb) {
      final val = bytes / kb;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} KB';
    }
    return '$bytes B';
  }

  /// Converts [bytes] into a localized Arabic file size string (بايت / كيلوبايت / ميجابايت / جيجابايت).
  static String formatFileSizeAr(int bytes) {
    if (bytes <= 0) return '0 ميجابايت';

    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;

    if (bytes >= gb) {
      final val = bytes / gb;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} جيجابايت';
    }
    if (bytes >= mb) {
      final val = bytes / mb;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} ميجابايت';
    }
    if (bytes >= kb) {
      final val = bytes / kb;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} كيلوبايت';
    }
    return '$bytes بايت';
  }

  /// Formats a progress percentage (0.0 – 1.0) as a string like `73%`.
  static String formatProgress(double progress) {
    final pct = (progress * 100).clamp(0, 100).round();
    return '$pct%';
  }

  /// Returns a display string for surah number in Arabic numeral style.
  static String formatSurahNumber(int number) {
    return number.toString().padLeft(3, '0');
  }
}
