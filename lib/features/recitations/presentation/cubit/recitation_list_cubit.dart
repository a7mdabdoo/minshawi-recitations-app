import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/recitation.dart';
import '../../domain/repositories/recitation_repository.dart';
import 'recitation_list_state.dart';

/// Drives the recitation list screen.
///
/// Lifecycle:
///   [loadRecitations] → Loading → Loaded | Error
///   [search]          → updates searchQuery on Loaded state
///   [refresh]         → forces a reload (alias for loadRecitations)
///   [markDownloaded]  → patches a single entry in Loaded state
///   [markRemoved]     → clears a single entry's local path in Loaded state
class RecitationListCubit extends Cubit<RecitationListState> {
  final RecitationRepository _repository;
  String? _currentCollectionId;

  RecitationListCubit(this._repository) : super(const RecitationListInitial());

  /// Reads the manifest asset and merges Hive download paths.
  Future<void> loadRecitations({String? collectionId}) async {
    _currentCollectionId = collectionId ?? _currentCollectionId;
    emit(const RecitationListLoading());
    try {
      final recitations = await _repository.getRecitations(
        collectionId: _currentCollectionId,
      );
      emit(RecitationListLoaded(recitations: recitations));
    } on CacheException catch (e) {
      emit(RecitationListError(e.message));
    } on ParseException catch (e) {
      emit(RecitationListError(e.message));
    } catch (e) {
      emit(RecitationListError('حدث خطأ غير متوقع: $e'));
    }
  }

  /// Alias — allows the UI "Retry" button to call a clearly named method.
  Future<void> refresh() => loadRecitations(collectionId: _currentCollectionId);

  /// Filters the currently loaded list by [query].
  /// No-op if not in [RecitationListLoaded] state.
  void search(String query) {
    final current = state;
    if (current is RecitationListLoaded) {
      emit(current.copyWith(searchQuery: query));
    }
  }

  /// Patches the [Recitation] with [recitationId] to reflect a completed download.
  /// Persists the path to Hive, then updates the in-memory state.
  Future<void> markDownloaded({
    required String recitationId,
    required String localFilePath,
  }) async {
    final current = state;
    if (current is! RecitationListLoaded) return;

    await _repository.saveDownloadedPath(
      recitationId: recitationId,
      localFilePath: localFilePath,
    );

    final updated = current.recitations.map((r) {
      if (r.id == recitationId) return r.copyWith(localFilePath: localFilePath);
      return r;
    }).toList();

    emit(current.copyWith(recitations: updated));
  }

  /// Removes the local file path for [recitationId] (e.g. file was deleted).
  Future<void> markRemoved(String recitationId) async {
    final current = state;
    if (current is! RecitationListLoaded) return;

    await _repository.removeDownloadedPath(recitationId);

    final updated = current.recitations.map((r) {
      if (r.id == recitationId) return r.copyWith(clearLocalFilePath: true);
      return r;
    }).toList();

    emit(current.copyWith(recitations: updated));
  }
}
