import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/nahawand_recitation_model.dart';
import '../models/recitation_model.dart';

class ManifestDataSource {
  const ManifestDataSource();

  static const int _schemaVersion = 5;
  static int? _loadedSchemaVersion;

  static List<RecitationModel>? _cachedAllModels;

  static List<NahawandRecitationModel>? _cachedNahawandModels;

  void _ensureCacheVersion() {
    if (_loadedSchemaVersion != _schemaVersion) {
      _cachedAllModels = null;
      _cachedNahawandModels = null;
      _loadedSchemaVersion = _schemaVersion;
    }
  }

  Future<List<NahawandRecitationModel>> loadNahawandCandidates() async {
    _ensureCacheVersion();
    if (_cachedNahawandModels != null) {
      return _cachedNahawandModels!;
    }

    late final String rawJson;
    try {
      rawJson = await rootBundle.loadString(AppConstants.nahawandAssetPath);
    } catch (e) {
      throw CacheException(
        'تعذّر تحميل ملف روائع النهاوند: ${AppConstants.nahawandAssetPath}\n$e',
      );
    }

    try {
      final List<dynamic> decoded = json.decode(rawJson) as List<dynamic>;
      final models = decoded
          .map((e) => NahawandRecitationModel.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
      _cachedNahawandModels = List.unmodifiable(models);
      return _cachedNahawandModels!;
    } on FormatException catch (e) {
      throw ParseException('خطأ في تنسيق ملف روائع النهاوند: ${e.message}');
    } catch (e) {
      throw ParseException('خطأ غير متوقع أثناء قراءة بيانات النهاوند: $e');
    }
  }

  Future<List<RecitationModel>> loadManifest({String? collectionId}) async {
    _ensureCacheVersion();
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

        try {
          final nahawandList = await loadNahawandCandidates();
          allModels.addAll(nahawandList);
        } catch (_) {}

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
