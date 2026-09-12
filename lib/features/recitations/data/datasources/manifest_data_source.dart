import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/recitation_model.dart';

/// Reads and parses the bundled [AppConstants.manifestAssetPath] JSON asset.
class ManifestDataSource {
  const ManifestDataSource();

  /// In-memory cache of all parsed models across collections.
  static List<RecitationModel>? _cachedAllModels;

  /// Returns the raw list of [RecitationModel] parsed from the asset bundle.
  /// If [collectionId] is provided, only models belonging to that collection are returned.
  ///
  /// Subsequent calls return from the in-memory cache instantly without I/O.
  Future<List<RecitationModel>> loadManifest({String? collectionId}) async {
    if (_cachedAllModels == null) {
      late final String rawJson;

      try {
        rawJson = await rootBundle.loadString(AppConstants.manifestAssetPath);
      } catch (e) {
        throw CacheException(
          'تعذّر تحميل ملف البيانات: ${AppConstants.manifestAssetPath}\n$e',
        );
      }

      try {
        final Map<String, dynamic> decoded =
            json.decode(rawJson) as Map<String, dynamic>;

        final List<RecitationModel> allModels = [];

        // Support multi-collection structure
        if (decoded.containsKey('collections')) {
          final collections = decoded['collections'] as List<dynamic>;
          for (final col in collections) {
            final colMap = col as Map<String, dynamic>;
            final cId = colMap['id'] as String? ?? 'rare_1387';
            final recs = colMap['recitations'] as List<dynamic>? ?? [];
            for (final r in recs) {
              final rMap = Map<String, dynamic>.from(r as Map<String, dynamic>);
              rMap['collectionId'] = cId;
              allModels.add(RecitationModel.fromJson(rMap));
            }
          }
        } else if (decoded.containsKey('recitations')) {
          final List<dynamic> list = decoded['recitations'] as List<dynamic>;
          allModels.addAll(
            list.map(
              (e) => RecitationModel.fromJson(e as Map<String, dynamic>),
            ),
          );
        }

        _cachedAllModels = List.unmodifiable(allModels);
      } on FormatException catch (e) {
        throw ParseException('خطأ في تنسيق ملف البيانات: ${e.message}');
      } catch (e) {
        throw ParseException('خطأ غير متوقع أثناء قراءة البيانات: $e');
      }
    }

    if (collectionId == null) {
      return _cachedAllModels!;
    }

    return _cachedAllModels!
        .where((m) => m.collectionId == collectionId)
        .toList(growable: false);
  }
}
