import 'package:equatable/equatable.dart';

abstract class FavoritesState extends Equatable {
  final Set<String> favoriteIds;

  const FavoritesState({this.favoriteIds = const {}});

  bool isFavorite(String recitationId) => favoriteIds.contains(recitationId);

  @override
  List<Object?> get props => [favoriteIds];
}

class FavoritesInitial extends FavoritesState {
  const FavoritesInitial() : super(favoriteIds: const {});
}

class FavoritesLoaded extends FavoritesState {
  const FavoritesLoaded(Set<String> favoriteIds)
      : super(favoriteIds: favoriteIds);
}
