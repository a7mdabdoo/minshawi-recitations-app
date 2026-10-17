import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/repositories/recitation_repository.dart';
import 'recitation_list_state.dart';

class RecitationListCubit extends Cubit<RecitationListState> {
  final RecitationRepository _repository;
  String? _currentCollectionId;

  RecitationListCubit(this._repository) : super(const RecitationListInitial());

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

  Future<void> refresh() => loadRecitations(collectionId: _currentCollectionId);

  void search(String query) {
    final current = state;
    if (current is RecitationListLoaded) {
      emit(current.copyWith(searchQuery: query));
    }
  }

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
