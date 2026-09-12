import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/playlist.dart';
import 'playlists_state.dart';

class PlaylistsCubit extends Cubit<PlaylistsState> {
  final Box<dynamic> _box;

  PlaylistsCubit(this._box) : super(const PlaylistsInitial()) {
    loadPlaylists();
  }

  void loadPlaylists() {
    try {
      final List<Playlist> list = [];
      for (final key in _box.keys) {
        final val = _box.get(key);
        if (val is Map) {
          list.add(Playlist.fromMap(val));
        }
      }
      // Sort newest first
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(PlaylistsLoaded(playlists: list));
    } catch (e) {
      emit(PlaylistsError('تعذر تحميل قوائم التشغيل: $e'));
    }
  }

  Future<Playlist> createPlaylist(String title, {String? initialRecitationId}) async {
    final trimmed = title.trim();
    final id = 'playlist_${DateTime.now().microsecondsSinceEpoch}_${_box.length}';
    final playlist = Playlist(
      id: id,
      title: trimmed.isEmpty ? 'قائمة جديدة' : trimmed,
      createdAt: DateTime.now(),
      recitationIds: initialRecitationId != null ? [initialRecitationId] : const [],
    );

    await _box.put(id, playlist.toMap());
    loadPlaylists();
    return playlist;
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _box.delete(playlistId);
    loadPlaylists();
  }

  Future<void> renamePlaylist(String playlistId, String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;

    final val = _box.get(playlistId);
    if (val is Map) {
      final playlist = Playlist.fromMap(val).copyWith(title: trimmed);
      await _box.put(playlistId, playlist.toMap());
      loadPlaylists();
    }
  }

  Future<bool> addRecitationToPlaylist(String playlistId, String recitationId) async {
    final val = _box.get(playlistId);
    if (val is Map) {
      final playlist = Playlist.fromMap(val);
      if (!playlist.recitationIds.contains(recitationId)) {
        final updatedList = List<String>.from(playlist.recitationIds)..add(recitationId);
        final updated = playlist.copyWith(recitationIds: updatedList);
        await _box.put(playlistId, updated.toMap());
        loadPlaylists();
        return true;
      }
    }
    return false;
  }

  Future<bool> removeRecitationFromPlaylist(String playlistId, String recitationId) async {
    final val = _box.get(playlistId);
    if (val is Map) {
      final playlist = Playlist.fromMap(val);
      if (playlist.recitationIds.contains(recitationId)) {
        final updatedList = List<String>.from(playlist.recitationIds)..remove(recitationId);
        final updated = playlist.copyWith(recitationIds: updatedList);
        await _box.put(playlistId, updated.toMap());
        loadPlaylists();
        return true;
      }
    }
    return false;
  }

  Future<void> toggleRecitationInPlaylist(String playlistId, String recitationId) async {
    final val = _box.get(playlistId);
    if (val is Map) {
      final playlist = Playlist.fromMap(val);
      if (playlist.recitationIds.contains(recitationId)) {
        await removeRecitationFromPlaylist(playlistId, recitationId);
      } else {
        await addRecitationToPlaylist(playlistId, recitationId);
      }
    }
  }
}
