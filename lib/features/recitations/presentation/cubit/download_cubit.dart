import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/download_service.dart';
import '../../domain/entities/recitation.dart';
import 'download_state.dart';
import 'recitation_list_cubit.dart';

class DownloadCubit extends Cubit<DownloadState> {
  final DownloadService _downloadService;
  final RecitationListCubit _recitationListCubit;
  final Map<String, CancelToken> _cancelTokens = {};
  final Set<String> _pausedRecitations = {};

  DownloadCubit({
    required DownloadService downloadService,
    required RecitationListCubit recitationListCubit,
  })  : _downloadService = downloadService,
        _recitationListCubit = recitationListCubit,
        super(const DownloadState());

  /// Starts downloading a recitation.
  Future<void> startDownload(Recitation recitation) async {
    // Guard 1: Ignore if already actively downloading
    if (state.isDownloading(recitation.id)) return;

    // Guard 2: If not in a paused session, check on-disk validity first
    if (!state.isPaused(recitation.id)) {
      final existingPath =
          await _downloadService.getValidLocalPath(recitation.id);
      if (existingPath != null) {
        await _recitationListCubit.markDownloaded(
          recitationId: recitation.id,
          localFilePath: existingPath,
        );
        return;
      }
    }

    final cancelToken = CancelToken();
    _cancelTokens[recitation.id] = cancelToken;
    _pausedRecitations.remove(recitation.id);

    // Update status to downloading and initialize progress from disk if partial
    final updatedStatusMap =
        Map<String, DownloadStatus>.from(state.statusMap);
    updatedStatusMap[recitation.id] = DownloadStatus.downloading;

    final updatedProgressMap = Map<String, double>.from(state.progressMap);
    final partialBytes =
        await _downloadService.getPartialFileSize(recitation);
    if (partialBytes > 0 && recitation.fileSizeBytes > 0) {
      updatedProgressMap[recitation.id] =
          (partialBytes / recitation.fileSizeBytes).clamp(0.0, 1.0);
    } else {
      updatedProgressMap.putIfAbsent(recitation.id, () => 0.0);
    }

    emit(state.copyWith(
      statusMap: updatedStatusMap,
      progressMap: updatedProgressMap,
      clearError: true,
    ));

    try {
      final localPath = await _downloadService.download(
        recitation: recitation,
        onProgress: (progress) {
          if (!isClosed && _cancelTokens.containsKey(recitation.id)) {
            final pMap = Map<String, double>.from(state.progressMap);
            pMap[recitation.id] = progress;
            emit(state.copyWith(progressMap: pMap));
          }
        },
        cancelToken: cancelToken,
      );

      if (!isClosed) {
        _cancelTokens.remove(recitation.id);
        _pausedRecitations.remove(recitation.id);

        final sMap = Map<String, DownloadStatus>.from(state.statusMap);
        sMap.remove(recitation.id);

        final pMap = Map<String, double>.from(state.progressMap);
        pMap.remove(recitation.id);

        emit(state.copyWith(
          statusMap: sMap,
          progressMap: pMap,
        ));

        // On native platforms, mark as downloaded in list cubit and Hive
        if (!kIsWeb) {
          await _recitationListCubit.markDownloaded(
            recitationId: recitation.id,
            localFilePath: localPath,
          );
        }
      }
    } on DownloadPausedException {
      // User paused download – maintain progress and update status to paused
      _handlePause(recitation.id);
    } on DownloadCancelledException {
      // User cancelled download – clean up state silently
      _handleCancellation(recitation.id);
    } on InsufficientStorageException catch (e) {
      if (!isClosed) {
        _cancelTokens.remove(recitation.id);
        _pausedRecitations.remove(recitation.id);

        final sMap = Map<String, DownloadStatus>.from(state.statusMap);
        sMap.remove(recitation.id);

        final pMap = Map<String, double>.from(state.progressMap);
        pMap.remove(recitation.id);

        emit(state.copyWith(
          statusMap: sMap,
          progressMap: pMap,
          lastError: e.message,
          errorRecitationId: recitation.id,
        ));
      }
    } catch (e) {
      if (cancelToken.isCancelled || _pausedRecitations.contains(recitation.id)) {
        _handlePause(recitation.id);
      } else if (!isClosed) {
        _cancelTokens.remove(recitation.id);
        _pausedRecitations.remove(recitation.id);

        final sMap = Map<String, DownloadStatus>.from(state.statusMap);
        sMap.remove(recitation.id);

        final pMap = Map<String, double>.from(state.progressMap);
        pMap.remove(recitation.id);

        final isStorageFull = e.toString().toLowerCase().contains('space') ||
            e.toString().toLowerCase().contains('disk full');

        emit(state.copyWith(
          statusMap: sMap,
          progressMap: pMap,
          lastError: isStorageFull
              ? 'مساحة التخزين غير كافية على الهاتف'
              : 'تعذّر تنزيل سورة ${recitation.surahNameAr}. يرجى التحقق من اتصال الإنترنت',
          errorRecitationId: recitation.id,
        ));
      }
    }
  }

  /// Resumes a paused download or starts from existing on-disk progress.
  Future<void> resumeDownload(Recitation recitation) {
    _pausedRecitations.remove(recitation.id);
    return startDownload(recitation);
  }

  /// Pauses an active download, keeping partial file on disk.
  void pauseDownload(String recitationId) {
    _pausedRecitations.add(recitationId);
    final token = _cancelTokens.remove(recitationId);
    if (token != null && !token.isCancelled) {
      token.cancel('pause');
    }
    _handlePause(recitationId);
  }

  void _handlePause(String recitationId) {
    _cancelTokens.remove(recitationId);
    _pausedRecitations.add(recitationId);
    if (!isClosed) {
      final sMap = Map<String, DownloadStatus>.from(state.statusMap);
      sMap[recitationId] = DownloadStatus.paused;
      emit(state.copyWith(statusMap: sMap, clearError: true));
    }
  }

  /// Cancels an active or paused download and deletes the partial file from disk.
  Future<void> cancelDownload(dynamic recitationOrId) async {
    final String recitationId = recitationOrId is Recitation
        ? recitationOrId.id
        : recitationOrId.toString();

    _pausedRecitations.remove(recitationId);
    final token = _cancelTokens.remove(recitationId);
    if (token != null && !token.isCancelled) {
      token.cancel('cancel');
    }
    await _downloadService.deleteDownload(recitationId);
    _handleCancellation(recitationId);
  }

  void _handleCancellation(String recitationId) {
    _cancelTokens.remove(recitationId);
    _pausedRecitations.remove(recitationId);
    if (!isClosed) {
      final sMap = Map<String, DownloadStatus>.from(state.statusMap);
      sMap.remove(recitationId);

      final pMap = Map<String, double>.from(state.progressMap);
      pMap.remove(recitationId);

      emit(state.copyWith(
        statusMap: sMap,
        progressMap: pMap,
        clearError: true,
      ));
    }
  }

  /// Deletes a previously downloaded recitation (or in-progress/paused session).
  Future<void> deleteDownload(Recitation recitation) async {
    if (kIsWeb) return;

    if (state.hasActiveSession(recitation.id)) {
      await cancelDownload(recitation.id);
      return;
    }

    try {
      await _downloadService.deleteDownload(recitation.id);
      if (!isClosed) {
        await _recitationListCubit.markRemoved(recitation.id);
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          lastError: 'فشل حذف الملف: $e',
          errorRecitationId: recitation.id,
        ));
      }
    }
  }

  @override
  Future<void> close() {
    for (final token in _cancelTokens.values) {
      token.cancel('pause');
    }
    _cancelTokens.clear();
    _pausedRecitations.clear();
    return super.close();
  }
}
