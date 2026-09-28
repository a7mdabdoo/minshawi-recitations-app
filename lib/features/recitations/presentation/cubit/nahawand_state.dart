import 'package:equatable/equatable.dart';
import '../../data/models/nahawand_recitation_model.dart';

/// Filter mode for the Nahawand section.
/// Defaults to [golden] (`is_golden_selection: true`).
enum NahawandFilterMode {
  /// Top 21 handpicked golden masterpieces (`is_golden_selection: true`).
  golden,

  /// All 188 documented historic concerts (`is_iconic_concert: true`).
  iconic,

  /// All 303 candidate Nahawand recitations.
  all,
}

sealed class NahawandState extends Equatable {
  const NahawandState();

  @override
  List<Object?> get props => [];
}

final class NahawandInitial extends NahawandState {
  const NahawandInitial();
}

final class NahawandLoading extends NahawandState {
  const NahawandLoading();
}

final class NahawandLoaded extends NahawandState {
  final List<NahawandRecitationModel> allRecitations;
  final List<NahawandRecitationModel> filteredRecitations;
  final NahawandFilterMode filterMode;
  final String? selectedCategory;
  final String searchQuery;

  const NahawandLoaded({
    required this.allRecitations,
    required this.filteredRecitations,
    this.filterMode = NahawandFilterMode.golden,
    this.selectedCategory,
    this.searchQuery = '',
  });

  int get goldenCount =>
      allRecitations.where((r) => r.isGoldenSelection).length;

  int get iconicCount =>
      allRecitations.where((r) => r.isIconicConcert).length;

  int get totalCount => allRecitations.length;

  NahawandLoaded copyWith({
    List<NahawandRecitationModel>? allRecitations,
    List<NahawandRecitationModel>? filteredRecitations,
    NahawandFilterMode? filterMode,
    String? selectedCategory,
    bool clearCategory = false,
    String? searchQuery,
  }) {
    return NahawandLoaded(
      allRecitations: allRecitations ?? this.allRecitations,
      filteredRecitations: filteredRecitations ?? this.filteredRecitations,
      filterMode: filterMode ?? this.filterMode,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        allRecitations,
        filteredRecitations,
        filterMode,
        selectedCategory,
        searchQuery,
      ];
}

final class NahawandError extends NahawandState {
  final String message;

  const NahawandError(this.message);

  @override
  List<Object?> get props => [message];
}
