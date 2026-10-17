abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class ServerException extends AppException {
  final int statusCode;
  const ServerException(super.message, {required this.statusCode});
}

class TimeoutException extends AppException {
  const TimeoutException() : super('انتهت مدة انتظار الشبكة');
}

class CacheException extends AppException {
  const CacheException(super.message);
}

class ParseException extends AppException {
  const ParseException(super.message);
}

class FileNotFoundException extends AppException {
  const FileNotFoundException(super.message);
}

class DownloadException extends AppException {
  const DownloadException(super.message);
}

class DownloadCancelledException extends AppException {
  const DownloadCancelledException([super.message = 'تم إلغاء التنزيل']);
}

class DownloadPausedException extends AppException {
  const DownloadPausedException([super.message = 'تم إيقاف التنزيل مؤقتاً']);
}

class PermissionException extends AppException {
  const PermissionException() : super('إذن التخزين مرفوض');
}

class InsufficientStorageException extends AppException {
  const InsufficientStorageException(
      [super.message = 'مساحة التخزين غير كافية على الهاتف']);
}
