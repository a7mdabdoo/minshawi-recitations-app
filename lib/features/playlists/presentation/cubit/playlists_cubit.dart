import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../recitations/domain/entities/recitation.dart';
import '../../../recitations/domain/repositories/recitation_repository.dart';
import '../../domain/entities/playlist.dart';
import 'playlists_state.dart';

class PlaylistsCubit extends Cubit<PlaylistsState> {
  final Box<dynamic> _box;
  final RecitationRepository? _repository;

  PlaylistsCubit(this._box, [this._repository]) : super(const PlaylistsInitial()) {
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

      if (list.isEmpty) {
        emit(const PlaylistsEmpty());
      } else {
        emit(PlaylistsLoaded(playlists: list));
      }

      // If repository is injected and some recitations are missing full models, enrich in background
      if (_repository != null) {
        _enrichPlaylistsWithFullRecitations(list);
      }
    } catch (e) {
      emit(PlaylistsError('تعذر تحميل قوائم التشغيل: $e'));
    }
  }

  Future<void> _enrichPlaylistsWithFullRecitations(List<Playlist> list) async {
    final repo = _repository;
    if (repo == null) return;

    bool hasMissing = false;
    for (final p in list) {
      if (p.recitations.length < p.recitationIds.length) {
        hasMissing = true;
        break;
      }
    }
    if (!hasMissing) return;

    try {
      final allRecitations = await repo.getRecitations();
      final recMap = {for (final r in allRecitations) r.id: r};
      bool anyUpdated = false;
      final enriched = <Playlist>[];

      for (final p in list) {
        if (p.recitations.length < p.recitationIds.length) {
          final existingIds = p.recitations.map((r) => r.id).toSet();
          final updatedRecs = List<Recitation>.from(p.recitations);
          for (final id in p.recitationIds) {
            if (!existingIds.contains(id) && recMap.containsKey(id)) {
              updatedRecs.add(recMap[id]!);
              anyUpdated = true;
            }
          }
          final updatedPlaylist = p.copyWith(recitations: updatedRecs);
          enriched.add(updatedPlaylist);
          await _box.put(updatedPlaylist.id, updatedPlaylist.toMap());
        } else {
          enriched.add(p);
        }
      }

      if (anyUpdated && !isClosed) {
        emit(PlaylistsLoaded(playlists: enriched));
      }
    } catch (_) {
      // Ignore background enrichment errors
    }
  }

  Future<Playlist> createPlaylist(
    String title, {
    String? initialRecitationId,
    Recitation? initialRecitation,
    String? description,
  }) async {
    final trimmed = title.trim();
    final id = 'playlist_${DateTime.now().microsecondsSinceEpoch}_${_box.length}';

    Recitation? rec = initialRecitation;
    final recId = rec?.id ?? initialRecitationId;

    final repo = _repository;
    if (rec == null && recId != null && recId.isNotEmpty && repo != null) {
      try {
        final all = await repo.getRecitations();
        rec = all.firstWhere((r) => r.id == recId);
      } catch (_) {}
    }

    final List<String> ids = (recId != null && recId.isNotEmpty) ? [recId] : const [];
    final List<Recitation> recs = rec != null ? [rec] : const [];

    final playlist = Playlist(
      id: id,
      title: trimmed.isEmpty ? 'قائمة جديدة' : trimmed,
      description: description ?? '',
      createdAt: DateTime.now(),
      recitationIds: ids,
      recitations: recs,
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

  Future<bool> addRecitationToPlaylist(
    String playlistId,
    String recitationId, [
    Recitation? recitation,
  ]) async {
    final val = _box.get(playlistId);
    if (val is Map) {
      final playlist = Playlist.fromMap(val);
      final id = recitation?.id ?? recitationId;
      if (id.isEmpty) return false;

      Recitation? effectiveRec = recitation;
      final repo = _repository;
      if (effectiveRec == null && repo != null) {
        try {
          final all = await repo.getRecitations();
          effectiveRec = all.firstWhere((r) => r.id == id);
        } catch (_) {}
      }

      if (!playlist.recitationIds.contains(id)) {
        final updatedIds = List<String>.from(playlist.recitationIds)..add(id);
        final updatedRecs = List<Recitation>.from(playlist.recitations);
        if (effectiveRec != null && !updatedRecs.any((r) => r.id == id)) {
          updatedRecs.add(effectiveRec);
        }

        final updated = playlist.copyWith(
          recitationIds: updatedIds,
          recitations: updatedRecs,
        );
        await _box.put(playlistId, updated.toMap());
        loadPlaylists();
        return true;
      }
    }
    return false;
  }

  Future<bool> removeRecitationFromPlaylist(
    String playlistId,
    String recitationId,
  ) async {
    final val = _box.get(playlistId);
    if (val is Map) {
      final playlist = Playlist.fromMap(val);
      if (playlist.recitationIds.contains(recitationId) ||
          playlist.recitations.any((r) => r.id == recitationId)) {
        final updatedIds = List<String>.from(playlist.recitationIds)
          ..remove(recitationId);
        final updatedRecs = List<Recitation>.from(playlist.recitations)
          ..removeWhere((r) => r.id == recitationId);
        final updated = playlist.copyWith(
          recitationIds: updatedIds,
          recitations: updatedRecs,
        );
        await _box.put(playlistId, updated.toMap());
        loadPlaylists();
        return true;
      }
    }
    return false;
  }

  Future<void> toggleRecitationInPlaylist(
    String playlistId,
    String recitationId, [
    Recitation? recitation,
  ]) async {
    final val = _box.get(playlistId);
    if (val is Map) {
      final playlist = Playlist.fromMap(val);
      final id = recitation?.id ?? recitationId;
      if (playlist.recitationIds.contains(id)) {
        await removeRecitationFromPlaylist(playlistId, id);
      } else {
        await addRecitationToPlaylist(playlistId, id, recitation);
      }
    }
  }
}
