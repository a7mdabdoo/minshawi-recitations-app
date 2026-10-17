import 'package:equatable/equatable.dart';
import '../../../recitations/domain/entities/recitation.dart';

abstract class DownloadedRecitationsState extends Equatable {
  const DownloadedRecitationsState();

  @override
  List<Object?> get props => [];
}

class DownloadedRecitationsInitial extends DownloadedRecitationsState {
  const DownloadedRecitationsInitial();
}

class DownloadedRecitationsLoading extends DownloadedRecitationsState {
  const DownloadedRecitationsLoading();
}

class DownloadedRecitationsLoaded extends DownloadedRecitationsState {
  final List<Recitation> allDownloaded;
  final List<Recitation> filteredDownloaded;
  final String? selectedCollectionId;
  final String searchQuery;
  final double totalSizeMb;

  const DownloadedRecitationsLoaded({
    required this.allDownloaded,
    required this.filteredDownloaded,
    this.selectedCollectionId,
    this.searchQuery = '',
    required this.totalSizeMb,
  });

  DownloadedRecitationsLoaded copyWith({
    List<Recitation>? allDownloaded,
    List<Recitation>? filteredDownloaded,
    String? selectedCollectionId,
    bool clearCollectionFilter = false,
    String? searchQuery,
    double? totalSizeMb,
  }) {
    return DownloadedRecitationsLoaded(
      allDownloaded: allDownloaded ?? this.allDownloaded,
      filteredDownloaded: filteredDownloaded ?? this.filteredDownloaded,
      selectedCollectionId: clearCollectionFilter
          ? null
          : (selectedCollectionId ?? this.selectedCollectionId),
      searchQuery: searchQuery ?? this.searchQuery,
      totalSizeMb: totalSizeMb ?? this.totalSizeMb,
    );
  }

  @override
  List<Object?> get props => [
        allDownloaded,
        filteredDownloaded,
        selectedCollectionId,
        searchQuery,
        totalSizeMb,
      ];
}

class DownloadedRecitationsError extends DownloadedRecitationsState {
  final String message;
  const DownloadedRecitationsError(this.message);

  @override
  List<Object?> get props => [message];
}
