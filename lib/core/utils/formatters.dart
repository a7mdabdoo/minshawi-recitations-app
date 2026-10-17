abstract class Formatters {
  Formatters._();

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

  static String formatDurationObj(Duration duration) {
    return formatDuration(duration.inSeconds);
  }

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

  static String formatProgress(double progress) {
    final pct = (progress * 100).clamp(0, 100).round();
    return '$pct%';
  }

  static String formatSurahNumber(int number) {
    return number.toString().padLeft(3, '0');
  }
}
