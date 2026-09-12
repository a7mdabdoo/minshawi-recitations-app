/// Base class for all domain-layer failures.
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Failure from a network/HTTP operation.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Failure when no internet connectivity is detected.
class NoConnectionFailure extends Failure {
  const NoConnectionFailure() : super('لا يوجد اتصال بالإنترنت');
}

/// Failure when a server returns an unexpected/error status code.
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

/// Failure for timeout errors.
class TimeoutFailure extends Failure {
  const TimeoutFailure() : super('انتهت مدة الاتصال بالخادم');
}

/// Failure for local storage/cache errors (Hive, path_provider).
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Failure when parsing JSON or model data fails.
class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

/// Failure when a file is expected on disk but is missing.
class FileNotFoundFailure extends Failure {
  const FileNotFoundFailure(super.message);
}

/// Failure during a download operation.
class DownloadFailure extends Failure {
  const DownloadFailure(super.message);
}

/// Failure when storage permissions are denied.
class PermissionFailure extends Failure {
  const PermissionFailure() : super('تم رفض إذن الوصول للتخزين');
}

/// Failure for unexpected/unknown errors.
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
