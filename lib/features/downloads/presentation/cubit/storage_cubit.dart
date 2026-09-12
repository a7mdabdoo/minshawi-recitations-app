import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/formatters.dart';
import 'storage_state.dart';

class StorageCubit extends Cubit<StorageState> {
  final StorageService _storageService;

  StorageCubit({required StorageService storageService})
      : _storageService = storageService,
        super(const StorageInitial());

  /// Calculates and loads current storage metrics.
  Future<void> loadStorage() async {
    try {
      if (state is! StorageLoaded) {
        emit(const StorageLoading());
      }
      final info = await _storageService.getStorageInfo();
      emit(StorageLoaded(storageInfo: info));
    } catch (e) {
      emit(StorageError('تعذّر حساب مساحة التخزين: $e'));
    }
  }

  /// Safely cleans cache, temporary fragments, and ImageCache.
  Future<void> cleanCache() async {
    final currentState = state;
    if (currentState is StorageLoaded) {
      emit(currentState.copyWith(isCleaning: true));
    } else {
      emit(const StorageLoading());
    }

    try {
      final freedBytes = await _storageService.clearCacheAndTemp();
      final updatedInfo = await _storageService.getStorageInfo();
      final formattedFreed = Formatters.formatFileSizeAr(freedBytes);

      emit(StorageLoaded(
        storageInfo: updatedInfo,
        isCleaning: false,
        successMessage: 'تم تنظيف الذاكرة المؤقتة بنجاح وتوفير $formattedFreed',
      ));
    } catch (e) {
      emit(StorageError('تعذّر تنظيف الذاكرة المؤقتة: $e'));
    }
  }

  /// Clears transient success messages.
  void clearMessage() {
    if (state is StorageLoaded) {
      final s = state as StorageLoaded;
      emit(s.copyWith(successMessage: null));
    }
  }
}
