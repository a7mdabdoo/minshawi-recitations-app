import 'package:equatable/equatable.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../domain/entities/recitation.dart';

/// All possible states of the recitation list screen.
abstract class RecitationListState extends Equatable {
  const RecitationListState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any load has been attempted.
class RecitationListInitial extends RecitationListState {
  const RecitationListInitial();
}

/// Asset is being read and parsed.
class RecitationListLoading extends RecitationListState {
  const RecitationListLoading();
}

/// Data loaded and ready to display.
class RecitationListLoaded extends RecitationListState {
  /// All recitations from the manifest, with download status merged in.
  final List<Recitation> recitations;

  /// The active search query (empty string = no filter).
  final String searchQuery;

  const RecitationListLoaded({
    required this.recitations,
    this.searchQuery = '',
  });

  /// Returns the filtered subset based on [searchQuery] using smart Arabic normalization.
  List<Recitation> get filtered {
    final q = searchQuery.trim();
    if (q.isEmpty) return recitations;

    final normQuery = ArabicNormalizer.normalize(q);

    return recitations.where((r) {
      return ArabicNormalizer.matches(r.surahNameAr, q) ||
          r.surahNameEn.toLowerCase().contains(normQuery) ||
          r.surahNumber.toString() == normQuery ||
          r.surahNumber.toString().contains(normQuery);
    }).toList();
  }

  RecitationListLoaded copyWith({
    List<Recitation>? recitations,
    String? searchQuery,
  }) {
    return RecitationListLoaded(
      recitations: recitations ?? this.recitations,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [recitations, searchQuery];
}

/// An error occurred while loading.
class RecitationListError extends RecitationListState {
  final String message;
  const RecitationListError(this.message);

  @override
  List<Object?> get props => [message];
}
