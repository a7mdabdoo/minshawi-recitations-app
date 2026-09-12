import 'package:equatable/equatable.dart';
import '../../domain/entities/playlist.dart';

abstract class PlaylistsState extends Equatable {
  const PlaylistsState();

  @override
  List<Object?> get props => [];
}

class PlaylistsInitial extends PlaylistsState {
  const PlaylistsInitial();
}

class PlaylistsLoading extends PlaylistsState {
  const PlaylistsLoading();
}

class PlaylistsLoaded extends PlaylistsState {
  final List<Playlist> playlists;
  final String? message;

  const PlaylistsLoaded({
    required this.playlists,
    this.message,
  });

  Playlist? getPlaylist(String id) {
    try {
      return playlists.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  bool isRecitationInPlaylist(String playlistId, String recitationId) {
    final p = getPlaylist(playlistId);
    return p != null &&
        (p.recitationIds.contains(recitationId) ||
            p.recitations.any((r) => r.id == recitationId));
  }

  PlaylistsLoaded copyWith({
    List<Playlist>? playlists,
    String? message,
  }) {
    return PlaylistsLoaded(
      playlists: playlists ?? this.playlists,
      message: message,
    );
  }

  @override
  List<Object?> get props => [playlists, message];
}

/// Explicit empty state for custom playlists.
/// Inherits from [PlaylistsLoaded] for seamless backward compatibility.
class PlaylistsEmpty extends PlaylistsLoaded {
  const PlaylistsEmpty({super.message}) : super(playlists: const []);
}

class PlaylistsError extends PlaylistsState {
  final String message;
  const PlaylistsError(this.message);

  @override
  List<Object?> get props => [message];
}
