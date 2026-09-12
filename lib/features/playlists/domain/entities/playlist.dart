import 'package:equatable/equatable.dart';

/// Represents a custom user-created playlist/collection.
class Playlist extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<String> recitationIds;

  const Playlist({
    required this.id,
    required this.title,
    required this.createdAt,
    this.recitationIds = const [],
  });

  Playlist copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    List<String>? recitationIds,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      recitationIds: recitationIds ?? this.recitationIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'recitationIds': recitationIds,
    };
  }

  factory Playlist.fromMap(Map<dynamic, dynamic> map) {
    return Playlist(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      recitationIds: (map['recitationIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [id, title, createdAt, recitationIds];
}
