import 'package:equatable/equatable.dart';

enum DownloadStatus {
  downloading,
  paused,
}

/// State representing all active/paused downloads and errors across the application.
class DownloadState extends Equatable {
  /// Map of recitationId -> progress value (0.0 .. 1.0).
  final Map<String, double> progressMap;

  /// Map of recitationId -> status (downloading or paused).
  final Map<String, DownloadStatus> statusMap;

  /// Error message when a download fails (null if no error).
  final String? lastError;

  /// ID of the recitation that caused the last error.
  final String? errorRecitationId;

  const DownloadState({
    this.progressMap = const {},
    this.statusMap = const {},
    this.lastError,
    this.errorRecitationId,
  });

  /// Check if a specific recitation is actively downloading.
  bool isDownloading(String recitationId) =>
      statusMap[recitationId] == DownloadStatus.downloading;

  /// Check if a specific recitation's download is paused.
  bool isPaused(String recitationId) =>
      statusMap[recitationId] == DownloadStatus.paused;

  /// Check if a recitation has an active or paused download session.
  bool hasActiveSession(String recitationId) =>
      statusMap.containsKey(recitationId);

  /// Get download progress for a specific recitation (defaults to 0.0).
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
