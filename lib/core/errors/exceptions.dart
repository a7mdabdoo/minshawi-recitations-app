/// Base class for all data-layer exceptions.
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a network call fails (no internet, DNS, etc.).
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Thrown when a server returns a non-2xx response.
class ServerException extends AppException {
  final int statusCode;
  const ServerException(super.message, {required this.statusCode});
}

/// Thrown when a Dio request times out.
class TimeoutException extends AppException {
  const TimeoutException() : super('انتهت مدة انتظار الشبكة');
}

/// Thrown when Hive or local persistence operations fail.
class CacheException extends AppException {
  const CacheException(super.message);
}

/// Thrown when JSON parsing fails.
class ParseException extends AppException {
  const ParseException(super.message);
}

/// Thrown when an expected local file cannot be found.
class FileNotFoundException extends AppException {
  const FileNotFoundException(super.message);
}

/// Thrown when a file download fails.
class DownloadException extends AppException {
  const DownloadException(super.message);
}

/// Thrown when a file download is cancelled by the user.
class DownloadCancelledException extends AppException {
  const DownloadCancelledException([super.message = 'تم إلغاء التنزيل']);
}

/// Thrown when a file download is paused by the user.
class DownloadPausedException extends AppException {
  const DownloadPausedException([super.message = 'تم إيقاف التنزيل مؤقتاً']);
}

/// Thrown when required storage permission is not granted.
class PermissionException extends AppException {
  const PermissionException() : super('إذن التخزين مرفوض');
}

/// Thrown when device storage is full or no space is left on the device.
class InsufficientStorageException extends AppException {
  const InsufficientStorageException([super.message = 'مساحة التخزين غير كافية على الهاتف']);
}
