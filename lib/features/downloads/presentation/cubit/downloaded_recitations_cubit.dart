import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/download_service.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../../recitations/data/datasources/local_recitation_data_source.dart';
import '../../../recitations/data/datasources/manifest_data_source.dart';
import '../../../recitations/domain/entities/recitation.dart';
import '../../../recitations/presentation/cubit/download_cubit.dart';
import '../../../recitations/presentation/cubit/download_state.dart';
import '../../../recitations/presentation/cubit/nahawand_cubit.dart';
import '../../../recitations/presentation/cubit/recitation_list_cubit.dart';
import 'downloaded_recitations_state.dart';

class DownloadedRecitationsCubit extends Cubit<DownloadedRecitationsState> {
  final ManifestDataSource _manifestDataSource;
  final LocalRecitationDataSource _localDataSource;
  final DownloadService _downloadService;
  final RecitationListCubit? _recitationListCubit;
  final NahawandCubit? _nahawandCubit;
  final DownloadCubit? _downloadCubit;

  StreamSubscription<DownloadState>? _downloadSub;

  DownloadedRecitationsCubit({
    required ManifestDataSource manifestDataSource,
    required LocalRecitationDataSource localDataSource,
    required DownloadService downloadService,
    RecitationListCubit? recitationListCubit,
    NahawandCubit? nahawandCubit,
    DownloadCubit? downloadCubit,
  })  : _manifestDataSource = manifestDataSource,
        _localDataSource = localDataSource,
        _downloadService = downloadService,
        _recitationListCubit = recitationListCubit,
        _nahawandCubit = nahawandCubit,
        _downloadCubit = downloadCubit,
        super(const DownloadedRecitationsInitial()) {
    _listenToDownloadCubit();
  }

  void _listenToDownloadCubit() {
    if (_downloadCubit != null) {
      _downloadSub = _downloadCubit.stream.listen((state) {
        if (this.state is DownloadedRecitationsLoaded) {
          final loaded = this.state as DownloadedRecitationsLoaded;
          loadDownloads(initialCollectionId: loaded.selectedCollectionId);
        }
      });
    }
  }

  double _calculateSizeMb(String path) {
    if (kIsWeb) return 0.0;
    try {
      final file = File(path);
      if (file.existsSync()) {
        return file.lengthSync() / (1024 * 1024);
      }
    } catch (_) {}
    return 0.0;
  }

  Future<String?> _resolveValidLocalPath(
    String recitationId,
    String? storedPath,
    Directory? downloadsDir,
  ) async {
    if (kIsWeb) {
      return storedPath;
    }

    if (storedPath != null && storedPath.isNotEmpty) {
      try {
        final f = File(storedPath);
        if (f.existsSync() && f.lengthSync() > 0) {
          return storedPath;
        }
      } catch (_) {}
    }

    if (downloadsDir != null && downloadsDir.existsSync()) {
      try {
        final entities = downloadsDir.listSync();
        for (final entity in entities) {
          if (entity is File) {
            final name = entity.path.split(RegExp(r'[/\\]')).last;
            if (name.startsWith('${recitationId}_') &&
                entity.lengthSync() > 0) {
              await _localDataSource.saveDownloadedPath(
                recitationId: recitationId,
                localFilePath: entity.path,
              );
              return entity.path;
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }

  Future<void> loadDownloads({String? initialCollectionId}) async {
    final currentCollectionId = initialCollectionId ??
        (state is DownloadedRecitationsLoaded
            ? (state as DownloadedRecitationsLoaded).selectedCollectionId
            : null);

    final currentQuery = state is DownloadedRecitationsLoaded
        ? (state as DownloadedRecitationsLoaded).searchQuery
        : '';

    emit(const DownloadedRecitationsLoading());

    try {
      final allModels =
          await _manifestDataSource.loadManifest(collectionId: null);

      final downloadedMap = _localDataSource.getAllDownloadedMap();

      Directory? downloadsDir;
      if (!kIsWeb) {
        try {
          final docsDir = await getApplicationDocumentsDirectory();
          downloadsDir =
              Directory('${docsDir.path}/${AppConstants.downloadsDirName}');
        } catch (_) {}
      }

      final List<Recitation> allDownloaded = [];
      double totalSize = 0.0;

      for (final model in allModels) {
        final storedPath = downloadedMap[model.id];
        final validPath = await _resolveValidLocalPath(
          model.id,
          storedPath,
          downloadsDir,
        );

        if (validPath != null) {
          final sizeMb = _calculateSizeMb(validPath);
          totalSize += sizeMb > 0
              ? sizeMb
              : (model.fileSizeBytes > 0
                  ? model.fileSizeBytes / (1024 * 1024)
                  : 0.0);

          allDownloaded.add(model.withLocalPath(validPath));
        }
      }

      final filtered = _applyFilters(
        all: allDownloaded,
        collectionId: currentCollectionId,
        query: currentQuery,
      );

      emit(
        DownloadedRecitationsLoaded(
          allDownloaded: List.unmodifiable(allDownloaded),
          filteredDownloaded: List.unmodifiable(filtered),
          selectedCollectionId: currentCollectionId,
          searchQuery: currentQuery,
          totalSizeMb: totalSize,
        ),
      );
    } catch (e) {
      emit(DownloadedRecitationsError('تعذّر تحميل التلاوات المحمّلة: $e'));
    }
  }

  void filterByCollection(String? collectionId) {
    final current = state;
    if (current is! DownloadedRecitationsLoaded) return;

    final targetCollection =
        (collectionId == null || collectionId == 'all') ? null : collectionId;

    final filtered = _applyFilters(
      all: current.allDownloaded,
      collectionId: targetCollection,
      query: current.searchQuery,
    );

    emit(
      current.copyWith(
        selectedCollectionId: targetCollection,
        clearCollectionFilter: targetCollection == null,
        filteredDownloaded: List.unmodifiable(filtered),
      ),
    );
  }

  void search(String query) {
    final current = state;
    if (current is! DownloadedRecitationsLoaded) return;

    final filtered = _applyFilters(
      all: current.allDownloaded,
      collectionId: current.selectedCollectionId,
      query: query,
    );

    emit(
      current.copyWith(
        searchQuery: query,
        filteredDownloaded: List.unmodifiable(filtered),
      ),
    );
  }

  List<Recitation> _applyFilters({
    required List<Recitation> all,
    required String? collectionId,
    required String query,
  }) {
    var result = all;

    if (collectionId != null && collectionId != 'all') {
      result = result.where((r) => r.collectionId == collectionId).toList();
    }

    final trimmedQuery = query.trim();
    if (trimmedQuery.isNotEmpty) {
      result = result.where((r) {
        return ArabicNormalizer.matchesMultiToken(
          query: trimmedQuery,
          sources: [
            r.surahNameAr,
            r.cleanSurahTitleWithVerses,
            r.recordingLocation,
            r.cleanLocationOrDetail,
            r.recordingYear,
            r.sourceLabel,
            r.verseRange,
            r.surahNumber.toString(),
          ],
        );
      }).toList();
    }

    return result;
  }

  Future<void> deleteRecitation(Recitation recitation) async {
    final current = state;
    if (current is! DownloadedRecitationsLoaded) return;

    try {
      await _downloadService.deleteDownload(recitation.id);
      await _localDataSource.removeDownloadedPath(recitation.id);

      _recitationListCubit?.markRemoved(recitation.id);
      _nahawandCubit?.markAsDeleted(recitation.id);

      final updatedAll =
          current.allDownloaded.where((r) => r.id != recitation.id).toList();

      final updatedFiltered = _applyFilters(
        all: updatedAll,
        collectionId: current.selectedCollectionId,
        query: current.searchQuery,
      );

      double newTotalSize = 0.0;
      for (final r in updatedAll) {
        if (r.localFilePath != null) {
          final s = _calculateSizeMb(r.localFilePath!);
          newTotalSize += s > 0 ? s : (r.fileSizeBytes / (1024 * 1024));
        }
      }

      emit(
        current.copyWith(
          allDownloaded: List.unmodifiable(updatedAll),
          filteredDownloaded: List.unmodifiable(updatedFiltered),
          totalSizeMb: newTotalSize,
        ),
      );
    } catch (e) {
      emit(DownloadedRecitationsError('فشل حذف التلاوة: $e'));
    }
  }

  @override
  Future<void> close() {
    _downloadSub?.cancel();
    return super.close();
  }
}
