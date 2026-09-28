import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../data/datasources/local_recitation_data_source.dart';
import '../../data/datasources/manifest_data_source.dart';
import '../../data/models/nahawand_recitation_model.dart';
import 'nahawand_state.dart';

/// Cubit responsible for loading, filtering, and searching Maqam Nahawand recitations.
class NahawandCubit extends Cubit<NahawandState> {
  final ManifestDataSource _manifestDataSource;
  final LocalRecitationDataSource _localDataSource;

  NahawandCubit({
    required ManifestDataSource manifestDataSource,
    required LocalRecitationDataSource localDataSource,
  })  : _manifestDataSource = manifestDataSource,
        _localDataSource = localDataSource,
        super(const NahawandInitial());

  /// Loads `assets/data/nahawand_candidates.json` and defaults to showing
  /// the Golden Selection (`is_golden_selection: true`).
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

  /// Changes the active filter mode (`golden`, `iconic`, or `all`).
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

  /// Filters by Surah category chip (or `null` for all categories).
  void setCategory(String? category) {
    final current = state;
    if (current is! NahawandLoaded) return;

    final nextCategory =
        current.selectedCategory == category ? null : category;

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

  /// Searches Nahawand recitations using [ArabicNormalizer].
  void search(String query) {
    final current = state;
    if (current is! NahawandLoaded) return;

    // When user types a search query while in `golden` mode, if golden has no matches,
    // automatically search across all Nahawand tracks so they find any recitation.
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

  /// Updates the local file path when a track finishes downloading.
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

  /// Clears the local file path when a downloaded file is deleted.
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
        (r) =>
            ArabicNormalizer.matches(r.title, trimmedQuery) ||
            ArabicNormalizer.matches(r.surah, trimmedQuery) ||
            ArabicNormalizer.matches(r.placeOrYear, trimmedQuery) ||
            ArabicNormalizer.matches(r.category, trimmedQuery) ||
            r.nahawandId.toString() == trimmedQuery,
      );
    }

    return result.toList(growable: false);
  }
}
