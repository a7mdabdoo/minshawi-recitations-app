import 'package:flutter_test/flutter_test.dart';
import 'package:al_minshawi_recitations/core/services/storage_service.dart';
import 'package:al_minshawi_recitations/features/downloads/presentation/cubit/storage_cubit.dart';
import 'package:al_minshawi_recitations/features/downloads/presentation/cubit/storage_state.dart';

class MockStorageService extends StorageService {
  int downloadedBytes = 50 * 1024 * 1024; // 50 MB
  int downloadedCount = 3;
  int cacheBytes = 10 * 1024 * 1024; // 10 MB

  @override
  Future<StorageInfo> getStorageInfo() async {
    return StorageInfo(
      downloadedAudioBytes: downloadedBytes,
      downloadedSurahsCount: downloadedCount,
      cacheAndTempBytes: cacheBytes,
    );
  }

  @override
  Future<int> clearCacheAndTemp() async {
    final freed = cacheBytes;
    cacheBytes = 0;
    return freed;
  }
}

void main() {
  group('StorageCubit Tests', () {
    late MockStorageService mockService;
    late StorageCubit cubit;

    setUp(() {
      mockService = MockStorageService();
      cubit = StorageCubit(storageService: mockService);
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state is StorageInitial', () {
      expect(cubit.state, equals(const StorageInitial()));
    });

    test('loadStorage emits StorageLoaded with accurate storage metrics', () async {
      await cubit.loadStorage();

      expect(cubit.state, isA<StorageLoaded>());
      final state = cubit.state as StorageLoaded;
      expect(state.storageInfo.downloadedAudioBytes, equals(50 * 1024 * 1024));
      expect(state.storageInfo.downloadedSurahsCount, equals(3));
      expect(state.storageInfo.cacheAndTempBytes, equals(10 * 1024 * 1024));
      expect(state.isCleaning, isFalse);
    });

    test('cleanCache clears cache and emits updated state with successMessage', () async {
      await cubit.loadStorage();
      await cubit.cleanCache();

      expect(cubit.state, isA<StorageLoaded>());
      final state = cubit.state as StorageLoaded;
      expect(state.storageInfo.cacheAndTempBytes, equals(0));
      expect(state.storageInfo.downloadedAudioBytes, equals(50 * 1024 * 1024)); // Preserved!
      expect(state.isCleaning, isFalse);
      expect(state.successMessage, contains('تم تنظيف الذاكرة المؤقتة بنجاح'));
      expect(state.successMessage, contains('10 ميجابايت'));
    });

    test('clearMessage resets successMessage to null', () async {
      await cubit.cleanCache();
      expect((cubit.state as StorageLoaded).successMessage, isNotNull);

      cubit.clearMessage();
      expect((cubit.state as StorageLoaded).successMessage, isNull);
    });
  });
}
