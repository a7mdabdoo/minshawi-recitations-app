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

class StorageService {
  const StorageService({dynamic localDataSource});

  Future<StorageInfo> getStorageInfo() async {
    return const StorageInfo(
      downloadedAudioBytes: 0,
      downloadedSurahsCount: 0,
      cacheAndTempBytes: 0,
    );
  }

  Future<int> clearCacheAndTemp() async {
    return 0;
  }
}
