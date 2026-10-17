import 'package:equatable/equatable.dart';

enum DownloadStatus {
  downloading,
  paused,
}

class DownloadState extends Equatable {
  final Map<String, double> progressMap;

  final Map<String, DownloadStatus> statusMap;

  final String? lastError;

  final String? errorRecitationId;

  const DownloadState({
    this.progressMap = const {},
    this.statusMap = const {},
    this.lastError,
    this.errorRecitationId,
  });

  bool isDownloading(String recitationId) =>
      statusMap[recitationId] == DownloadStatus.downloading;

  bool isPaused(String recitationId) =>
      statusMap[recitationId] == DownloadStatus.paused;

  bool hasActiveSession(String recitationId) =>
      statusMap.containsKey(recitationId);

  double getProgress(String recitationId) => progressMap[recitationId] ?? 0.0;

  DownloadState copyWith({
    Map<String, double>? progressMap,
    Map<String, DownloadStatus>? statusMap,
    String? lastError,
    String? errorRecitationId,
    bool clearError = false,
  }) {
    return DownloadState(
      progressMap: progressMap ?? this.progressMap,
      statusMap: statusMap ?? this.statusMap,
      lastError: clearError ? null : (lastError ?? this.lastError),
      errorRecitationId:
          clearError ? null : (errorRecitationId ?? this.errorRecitationId),
    );
  }

  @override
  List<Object?> get props => [
        progressMap,
        statusMap,
        lastError,
        errorRecitationId,
      ];
}
