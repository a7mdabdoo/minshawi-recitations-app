import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final Box<dynamic> _favoritesBox;
  static const String _favoritesKey = 'user_favorites_list';

  FavoritesCubit(this._favoritesBox) : super(const FavoritesInitial()) {
    _loadFavorites();
  }

  void _loadFavorites() {
    try {
      final dynamic raw = _favoritesBox.get(_favoritesKey);
      if (raw is Iterable) {
        final set = raw.map((e) => e.toString()).toSet();
        emit(FavoritesLoaded(set));
        return;
      }
    } catch (_) {}
    emit(const FavoritesLoaded(<String>{}));
  }

  bool isFavorite(String recitationId) {
    return state.favoriteIds.contains(recitationId);
  }

  Future<void> toggleFavorite(String recitationId) async {
    final current = Set<String>.from(state.favoriteIds);
    if (current.contains(recitationId)) {
      current.remove(recitationId);
    } else {
      current.add(recitationId);
    }

    emit(FavoritesLoaded(current));
    await _favoritesBox.put(_favoritesKey, current.toList());
  }
}
