import 'package:equatable/equatable.dart';

import '../../../recitations/data/models/recitation_model.dart';
import '../../../recitations/domain/entities/recitation.dart';

/// Represents a custom user-created playlist/collection.
class Playlist extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final List<String> recitationIds;
  final List<Recitation> recitations;

  const Playlist({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAt,
    this.recitationIds = const [],
    this.recitations = const [],
  });

  /// Alias for title for consistency with user code / search queries.
  String get name => title;

  Playlist copyWith({
    String? id,
    String? title,
    String? name,
    String? description,
    DateTime? createdAt,
    List<String>? recitationIds,
    List<Recitation>? recitations,
  }) {
    final effectiveTitle = name ?? title ?? this.title;
    final effectiveRecitations = recitations ?? this.recitations;

    List<String> effectiveIds;
    if (recitationIds != null) {
      effectiveIds = recitationIds;
    } else if (recitations != null) {
      effectiveIds = recitations.map((r) => r.id).toList();
    } else {
      effectiveIds = this.recitationIds;
    }

    return Playlist(
      id: id ?? this.id,
      title: effectiveTitle,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      recitationIds: effectiveIds,
      recitations: effectiveRecitations,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'name': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'recitationIds': recitationIds,
      'recitations': recitations.map((r) {
        if (r is RecitationModel) {
          return r.toJson();
        }
        return {
          'id': r.id,
          'surahNumber': r.surahNumber,
          'surahNameAr': r.surahNameAr,
          'surahNameEn': r.surahNameEn,
          'verseRange': r.verseRange,
          'durationSeconds': r.durationSeconds,
          'fileSizeBytes': r.fileSizeBytes,
          'audioUrl': r.audioUrl,
          'recordingYear': r.recordingYear,
          'recordingLocation': r.recordingLocation,
          'collectionId': r.collectionId,
          'isRare': r.isRare,
          'quality': r.quality,
          if (r.localFilePath != null) 'localFilePath': r.localFilePath,
        };
      }).toList(),
    };
  }

  factory Playlist.fromMap(Map<dynamic, dynamic> map) {
    final recitationsList = <Recitation>[];
    if (map['recitations'] is List) {
      for (final item in (map['recitations'] as List)) {
        if (item is Map) {
          try {
            recitationsList.add(
              RecitationModel.fromJson(
                Map<String, dynamic>.from(
                  item.map((k, v) => MapEntry(k?.toString() ?? '', v)),
                ),
              ),
            );
          } catch (_) {
            // Ignore malformed individual item
          }
        }
      }
    }

    final rawIds = (map['recitationIds'] as List<dynamic>?)
            ?.map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList() ??
        const <String>[];

    final Set<String> idSet = Set<String>.from(rawIds);
    for (final r in recitationsList) {
      if (r.id.isNotEmpty) {
        idSet.add(r.id);
      }
    }

    final rawTitle = (map['title'] ?? map['name'])?.toString() ?? '';

    return Playlist(
      id: map['id']?.toString() ?? '',
      title: rawTitle.isEmpty ? 'قائمة جديدة' : rawTitle,
      description: map['description']?.toString() ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      recitationIds: idSet.toList(),
      recitations: recitationsList,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        createdAt,
        recitationIds,
        recitations,
      ];
}
