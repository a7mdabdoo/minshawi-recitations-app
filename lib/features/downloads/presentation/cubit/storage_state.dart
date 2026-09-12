import 'package:equatable/equatable.dart';
import '../../../../core/services/storage_service.dart';

abstract class StorageState extends Equatable {
  const StorageState();

  @override
  List<Object?> get props => [];
}

class StorageInitial extends StorageState {
  const StorageInitial();
}

class StorageLoading extends StorageState {
  const StorageLoading();
}

class StorageLoaded extends StorageState {
  final StorageInfo storageInfo;
  final bool isCleaning;
  final String? successMessage;

  const StorageLoaded({
    required this.storageInfo,
    this.isCleaning = false,
    this.successMessage,
  });

  StorageLoaded copyWith({
    StorageInfo? storageInfo,
    bool? isCleaning,
    String? successMessage,
  }) {
    return StorageLoaded(
      storageInfo: storageInfo ?? this.storageInfo,
      isCleaning: isCleaning ?? this.isCleaning,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        storageInfo.downloadedAudioBytes,
        storageInfo.cacheAndTempBytes,
        storageInfo.downloadedSurahsCount,
        isCleaning,
        successMessage,
      ];
}

class StorageError extends StorageState {
  final String message;
  const StorageError(this.message);

  @override
  List<Object?> get props => [message];
}
