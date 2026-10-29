import 'package:equatable/equatable.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../domain/entities/recitation.dart';

abstract class RecitationListState extends Equatable {
  const RecitationListState();

  @override
  List<Object?> get props => [];
}

class RecitationListInitial extends RecitationListState {
  const RecitationListInitial();
}

class RecitationListLoading extends RecitationListState {
  const RecitationListLoading();
}

class RecitationListLoaded extends RecitationListState {
  final List<Recitation> recitations;

  final String searchQuery;

  const RecitationListLoaded({
    required this.recitations,
    this.searchQuery = '',
  });

  List<Recitation> get filtered {
    final q = searchQuery.trim();
    if (q.isEmpty) return recitations;

    return recitations.where((r) {
      return ArabicNormalizer.matchesMultiToken(
        query: q,
        sources: [
          r.surahNameAr,
          r.cleanSurahTitleWithVerses,
          r.recordingLocation,
          r.cleanLocationOrDetail,
          r.recordingYear,
          r.verseRange,
          r.sourceLabel,
          r.surahNameEn,
          r.surahNumber.toString(),
        ],
      );
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

class RecitationListError extends RecitationListState {
  final String message;
  const RecitationListError(this.message);

  @override
  List<Object?> get props => [message];
}
