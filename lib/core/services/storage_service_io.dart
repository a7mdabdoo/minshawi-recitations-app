import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/recitations/data/datasources/local_recitation_data_source.dart';
import '../constants/app_constants.dart';

/// Holds detailed disk storage and cache usage metrics.
class StorageInfo {
  final int downloadedAudioBytes;
  final int downloadedSurahsCount;
  final int cacheAndTempBytes;
  final int? freeDiskBytes;

  const StorageInfo({
    required this.downloadedAudioBytes,
    required this.downloadedSurahsCount,
    required this.cacheAndTempBytes,
    this.freeDiskBytes,
  });

  StorageInfo copyWith({
    int? downloadedAudioBytes,
    int? downloadedSurahsCount,
    int? cacheAndTempBytes,
    int? freeDiskBytes,
  }) {
    return StorageInfo(
      downloadedAudioBytes: downloadedAudioBytes ?? this.downloadedAudioBytes,
      downloadedSurahsCount:
          downloadedSurahsCount ?? this.downloadedSurahsCount,
      cacheAndTempBytes: cacheAndTempBytes ?? this.cacheAndTempBytes,
      freeDiskBytes: freeDiskBytes ?? this.freeDiskBytes,
    );
  }
}

/// Mobile/Desktop service responsible for calculating storage breakdown
/// and safely performing temporary cache cleanups.
class StorageService {
  final LocalRecitationDataSource? _localDataSource;

  const StorageService({
    LocalRecitationDataSource? localDataSource,
  }) : _localDataSource = localDataSource;

  /// Calculates total size of downloaded recitations, cache, and temporary fragments.
  Future<StorageInfo> getStorageInfo() async {
    int downloadedBytes = 0;
    int downloadedCount = 0;
    int cacheBytes = 0;

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final downloadsDir =
          Directory('${docsDir.path}/${AppConstants.downloadsDirName}');

      final downloadedMap =
          _localDataSource?.getAllDownloadedMap() ?? const {};
      for (final entry in downloadedMap.entries) {
        final filePath = entry.value;
        final file = File(filePath);
        if (file.existsSync()) {
          downloadedBytes += file.lengthSync();
          downloadedCount++;
        }
      }

      // Scan downloads directory for orphaned .tmp or untracked audio files
      if (downloadsDir.existsSync()) {
        final entities = downloadsDir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File) {
            final path = entity.path.toLowerCase();
            if (path.endsWith('.tmp') ||
                path.endsWith('.temp') ||
                path.endsWith('.part')) {
              cacheBytes += entity.lengthSync();
            } else if (path.endsWith('.mp3') &&
                !downloadedMap.containsValue(entity.path)) {
              downloadedBytes += entity.lengthSync();
              downloadedCount++;
            }
          }
        }
      }

      // Scan root docs directory for any loose .tmp files
      if (docsDir.existsSync()) {
        for (final entity in docsDir.listSync()) {
          if (entity is File) {
            final path = entity.path.toLowerCase();
            if (path.endsWith('.tmp') ||
                path.endsWith('.temp') ||
                path.endsWith('.part')) {
              cacheBytes += entity.lengthSync();
            }
          }
        }
      }

      try {
        final tempDir = await getTemporaryDirectory();
        if (tempDir.existsSync()) {
          for (final entity in tempDir.listSync(recursive: true)) {
            if (entity is File) {
              cacheBytes += entity.lengthSync();
            }
          }
        }
      } catch (_) {}

      return StorageInfo(
        downloadedAudioBytes: downloadedBytes,
        downloadedSurahsCount: downloadedCount,
        cacheAndTempBytes: cacheBytes,
      );
    } catch (_) {
      return StorageInfo(
        downloadedAudioBytes: downloadedBytes,
        downloadedSurahsCount: downloadedCount,
        cacheAndTempBytes: cacheBytes,
      );
    }
  }

  /// Safely deletes ONLY .tmp / cache fragments and clears ImageCache.
  /// Strictly preserves all downloaded .mp3 recitations and Hive databases.
  Future<int> clearCacheAndTemp() async {
    int freedBytes = 0;

    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {}

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final downloadsDir =
          Directory('${docsDir.path}/${AppConstants.downloadsDirName}');

      if (downloadsDir.existsSync()) {
        for (final entity in downloadsDir.listSync(recursive: true)) {
          if (entity is File) {
            final path = entity.path.toLowerCase();
            if (path.endsWith('.tmp') ||
                path.endsWith('.temp') ||
                path.endsWith('.part')) {
              freedBytes += entity.lengthSync();
              try {
                entity.deleteSync();
              } catch (_) {}
            }
          }
        }
      }

      if (docsDir.existsSync()) {
        for (final entity in docsDir.listSync()) {
          if (entity is File) {
            final path = entity.path.toLowerCase();
            if (path.endsWith('.tmp') ||
                path.endsWith('.temp') ||
                path.endsWith('.part')) {
              freedBytes += entity.lengthSync();
              try {
                entity.deleteSync();
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}

    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        for (final entity in tempDir.listSync(recursive: false)) {
          try {
            if (entity is File) {
              freedBytes += entity.lengthSync();
              entity.deleteSync();
            } else if (entity is Directory) {
              for (final sub in entity.listSync(recursive: true)) {
                if (sub is File) {
                  freedBytes += sub.lengthSync();
                }
              }
              entity.deleteSync(recursive: true);
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    return freedBytes;
  }
}
