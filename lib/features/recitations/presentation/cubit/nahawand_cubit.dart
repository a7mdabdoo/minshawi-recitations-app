import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../data/datasources/local_recitation_data_source.dart';
import '../../data/datasources/manifest_data_source.dart';
import '../../data/models/nahawand_recitation_model.dart';
import 'nahawand_state.dart';

class NahawandCubit extends Cubit<NahawandState> {
  final ManifestDataSource _manifestDataSource;
  final LocalRecitationDataSource _localDataSource;

  NahawandCubit({
    required ManifestDataSource manifestDataSource,
    required LocalRecitationDataSource localDataSource,
  })  : _manifestDataSource = manifestDataSource,
        _localDataSource = localDataSource,
        super(const NahawandInitial());

  Future<void> loadNahawandRecitations() async {
    if (state is NahawandLoaded) return;

    emit(const NahawandLoading());
    try {
      final rawModels = await _manifestDataSource.loadNahawandCandidates();
      final downloadedMap = _localDataSource.getAllDownloadedMap();

      final enriched = rawModels.map((model) {
        final localPath = downloadedMap[model.id];
        return localPath != null ? model.withLocalPath(localPath) : model;
      }).toList(growable: false);

      final initialFiltered = _applyFilters(
        all: enriched,
        mode: NahawandFilterMode.golden,
        category: null,
        query: '',
      );

      emit(
        NahawandLoaded(
          allRecitations: enriched,
          filteredRecitations: initialFiltered,
          filterMode: NahawandFilterMode.golden,
        ),
      );
    } catch (e) {
      emit(NahawandError('تعذّر تحميل روائع النهاوند: $e'));
    }
  }

  void setFilterMode(NahawandFilterMode mode) {
    final current = state;
    if (current is! NahawandLoaded) return;

    final filtered = _applyFilters(
      all: current.allRecitations,
      mode: mode,
      category: current.selectedCategory,
      query: current.searchQuery,
    );

    emit(
      current.copyWith(
        filterMode: mode,
        filteredRecitations: filtered,
      ),
    );
  }

  void setCategory(String? category) {
    final current = state;
    if (current is! NahawandLoaded) return;

    final nextCategory = current.selectedCategory == category ? null : category;

    final filtered = _applyFilters(
      all: current.allRecitations,
      mode: current.filterMode,
      category: nextCategory,
      query: current.searchQuery,
    );

    emit(
      current.copyWith(
        selectedCategory: nextCategory,
        clearCategory: nextCategory == null,
        filteredRecitations: filtered,
      ),
    );
  }

  void search(String query) {
    final current = state;
    if (current is! NahawandLoaded) return;

    var effectiveMode = current.filterMode;
    var filtered = _applyFilters(
      all: current.allRecitations,
      mode: effectiveMode,
      category: current.selectedCategory,
      query: query,
    );

    if (query.trim().isNotEmpty &&
        filtered.isEmpty &&
        effectiveMode != NahawandFilterMode.all) {
      effectiveMode = NahawandFilterMode.all;
      filtered = _applyFilters(
        all: current.allRecitations,
        mode: effectiveMode,
        category: current.selectedCategory,
        query: query,
      );
    }

    emit(
      current.copyWith(
        filterMode: effectiveMode,
        searchQuery: query,
        filteredRecitations: filtered,
      ),
    );
  }

  void clearSearch() => search('');

  void markAsDownloaded(String recitationId, String localFilePath) {
    final current = state;
    if (current is! NahawandLoaded) return;

    final updatedAll = current.allRecitations.map((r) {
      return r.id == recitationId ? r.withLocalPath(localFilePath) : r;
    }).toList(growable: false);

    final updatedFiltered = _applyFilters(
      all: updatedAll,
      mode: current.filterMode,
      category: current.selectedCategory,
      query: current.searchQuery,
    );

    emit(
      current.copyWith(
        allRecitations: updatedAll,
        filteredRecitations: updatedFiltered,
      ),
    );
  }

  void markAsDeleted(String recitationId) {
    final current = state;
    if (current is! NahawandLoaded) return;

    final updatedAll = current.allRecitations.map((r) {
      return r.id == recitationId ? r.withLocalPath(null) : r;
    }).toList(growable: false);

    final updatedFiltered = _applyFilters(
      all: updatedAll,
      mode: current.filterMode,
      category: current.selectedCategory,
      query: current.searchQuery,
    );

    emit(
      current.copyWith(
        allRecitations: updatedAll,
        filteredRecitations: updatedFiltered,
      ),
    );
  }

  List<NahawandRecitationModel> _applyFilters({
    required List<NahawandRecitationModel> all,
    required NahawandFilterMode mode,
    required String? category,
    required String query,
  }) {
    Iterable<NahawandRecitationModel> result = all;

    switch (mode) {
      case NahawandFilterMode.golden:
        result = result.where((r) => r.isGoldenSelection);
      case NahawandFilterMode.iconic:
        result = result.where((r) => r.isIconicConcert);
      case NahawandFilterMode.all:
        break;
    }

    if (category != null && category.isNotEmpty) {
      result = result.where((r) => r.category == category);
    }

    final trimmedQuery = query.trim();
    if (trimmedQuery.isNotEmpty) {
      result = result.where(
        (r) => ArabicNormalizer.matchesMultiToken(
          query: trimmedQuery,
          sources: [
            r.title,
            r.surah,
            r.placeOrYear,
            r.category,
            r.tag,
            r.cleanSurahTitleWithVerses,
            r.cleanLocationOrDetail,
            r.nahawandId.toString(),
          ],
        ),
      );
    }

    return result.toList(growable: false);
  }
}
