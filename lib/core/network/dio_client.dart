import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// Factory that builds and configures the singleton [Dio] client.
class DioClient {
  DioClient._();

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _buildDio();
    return _instance!;
  }

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: AppConstants.connectTimeoutSeconds),
        receiveTimeout: const Duration(seconds: AppConstants.receiveTimeoutSeconds),
        headers: {
          'Accept': 'application/json, audio/*, */*',
          'User-Agent': 'AlMinshawi-RecitationsApp/1.0',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.addAll([
      _LogInterceptor(),
      _ErrorInterceptor(),
    ]);

    return dio;
  }
}

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[DIO] → ${options.method} ${options.uri}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[DIO] ← ${response.statusCode} ${response.realUri}');
      return true;
    }());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[DIO] ✗ ${err.type} – ${err.message}');
      return true;
    }());
    handler.next(err);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return handler.reject(
          err.copyWith(
            error: const TimeoutException(),
          ),
        );

      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        return handler.reject(
          err.copyWith(
            error: ServerException(
              'خطأ في الخادم ($status)',
              statusCode: status,
            ),
          ),
        );

      case DioExceptionType.connectionError:
        return handler.reject(
          err.copyWith(
            error: const NetworkException('تعذّر الاتصال بالشبكة'),
          ),
        );

      default:
        return handler.next(err);
    }
  }
}

/// Maps a [DioException] to the appropriate [AppException].
AppException dioExceptionToAppException(DioException e) {
  if (e.error is AppException) return e.error as AppException;

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const TimeoutException();
    case DioExceptionType.badResponse:
      return ServerException(
        'خطأ في الخادم',
        statusCode: e.response?.statusCode ?? 0,
      );
    case DioExceptionType.connectionError:
      return const NetworkException('تعذّر الاتصال');
    default:
      return NetworkException(e.message ?? 'خطأ غير معروف في الشبكة');
  }
}
