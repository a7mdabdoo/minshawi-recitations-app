abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class NoConnectionFailure extends Failure {
  const NoConnectionFailure() : super('لا يوجد اتصال بالإنترنت');
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure() : super('انتهت مدة الاتصال بالخادم');
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

class FileNotFoundFailure extends Failure {
  const FileNotFoundFailure(super.message);
}

class DownloadFailure extends Failure {
  const DownloadFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure() : super('تم رفض إذن الوصول للتخزين');
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
