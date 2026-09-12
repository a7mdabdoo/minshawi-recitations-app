/// Platform-aware entry point for [DownloadService].
///
/// The Dart compiler resolves the correct implementation at compile time:
///
///   • **Web**    (`dart.library.js_interop` is available):
///       [download_service_web.dart] — browser anchor-element download;
///       no `dart:io`, no `path_provider`.
///
///   • **Mobile / Desktop** (`dart.library.io` is available):
///       [download_service_io.dart] — Dio + local file cache via
///       `path_provider` and Hive.
///
/// All consumers (`DownloadCubit`, `service_locator.dart`) import this file
/// and receive a `DownloadService` class with an identical public API
/// regardless of platform.
library;

export 'download_service_io.dart'
    if (dart.library.js_interop) 'download_service_web.dart';
