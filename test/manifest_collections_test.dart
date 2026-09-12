import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recitations_manifest.json includes all 3 collections including mojawad', () {
    final file = File('assets/data/recitations_manifest.json');
    expect(file.existsSync(), isTrue);

    final jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final collections = jsonMap['collections'] as List<dynamic>;

    expect(collections.length, equals(3));

    final mojawad = collections.firstWhere((c) => c['id'] == 'mojawad') as Map<String, dynamic>;
    expect(mojawad['titleAr'], equals('المصحف المجود'));
    expect(mojawad['totalSurahs'], equals(114));

    final recitations = mojawad['recitations'] as List<dynamic>;
    expect(recitations.length, equals(114));

    // Check first and last surah URLs
    final first = recitations.first as Map<String, dynamic>;
    expect(first['surahNumber'], equals(1));
    expect(first['surahNameAr'], equals('الفاتحة'));
    expect(first['audioUrl'], equals('https://server10.mp3quran.net/minsh/Almusshaf-Al-Mojawwad/001.mp3'));

    final last = recitations.last as Map<String, dynamic>;
    expect(last['surahNumber'], equals(114));
    expect(last['surahNameAr'], equals('الناس'));
    expect(last['audioUrl'], equals('https://server10.mp3quran.net/minsh/Almusshaf-Al-Mojawwad/114.mp3'));
  });
}
