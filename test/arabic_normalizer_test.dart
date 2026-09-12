import 'package:flutter_test/flutter_test.dart';
import 'package:al_minshawi_recitations/core/utils/arabic_normalizer.dart';
import 'package:al_minshawi_recitations/features/recitations/domain/entities/recitation.dart';
import 'package:al_minshawi_recitations/features/recitations/presentation/cubit/recitation_list_state.dart';

void main() {
  group('ArabicNormalizer.normalize', () {
    test('removes Tashkeel and diacritics', () {
      const input = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
      expect(ArabicNormalizer.normalize(input), equals('بسم الله الرحمن الرحيم'));
    });

    test('normalizes Alef variants', () {
      expect(ArabicNormalizer.normalize('أحمد'), equals('احمد'));
      expect(ArabicNormalizer.normalize('إبراهيم'), equals('ابراهيم'));
      expect(ArabicNormalizer.normalize('آدم'), equals('ادم'));
      expect(ArabicNormalizer.normalize('ٱلقرآن'), equals('القران'));
    });

    test('normalizes Taa Marbuta to Haa', () {
      expect(ArabicNormalizer.normalize('البقرة'), equals('البقره'));
      expect(ArabicNormalizer.normalize('الفاتحة'), equals('الفاتحه'));
    });

    test('normalizes Alef Maksura to Yaa', () {
      expect(ArabicNormalizer.normalize('موسى'), equals('موسي'));
      expect(ArabicNormalizer.normalize('يس'), equals('يس'));
    });

    test('normalizes Arabic-Indic digits to ASCII', () {
      expect(ArabicNormalizer.normalize('سورة ١١٤'), equals('سوره 114'));
      expect(ArabicNormalizer.normalize('٢'), equals('2'));
    });
  });

  group('ArabicNormalizer.matches', () {
    test('matches exact and normalized queries', () {
      expect(ArabicNormalizer.matches('سورة البقرة', 'البقره'), isTrue);
      expect(ArabicNormalizer.matches('سورة البقرة', 'بقرة'), isTrue);
      expect(ArabicNormalizer.matches('سورة آل عمران', 'ال عمران'), isTrue);
      expect(ArabicNormalizer.matches('سورة الإسراء', 'اسراء'), isTrue);
      expect(ArabicNormalizer.matches('سورة الكهف', 'الكهف'), isTrue);
      expect(ArabicNormalizer.matches('سورة الكهف', 'كهف'), isTrue);
    });

    test('matches Tashkeel queries against plain text and vice versa', () {
      expect(ArabicNormalizer.matches('سورة الكهف', 'الْكَهْف'), isTrue);
      expect(ArabicNormalizer.matches('سُورَةُ الْكَهْفِ', 'الكهف'), isTrue);
    });
  });

  group('RecitationListLoaded.filtered with smart search', () {
    final sampleRecitations = [
      const Recitation(
        id: 'murattal_001',
        surahNumber: 1,
        surahNameAr: 'الفاتحة',
        surahNameEn: 'Al-Fatihah',
        verseRange: '1-7',
        durationSeconds: 120,
        fileSizeBytes: 1000000,
        audioUrl: 'https://server10.mp3quran.net/minsh/001.mp3',
        recordingYear: 'المصحف المرتل',
        recordingLocation: 'القاهرة',
        collectionId: 'complete_murattal',
        quality: 'مرتل عالي الجودة',
        isRare: false,
      ),
      const Recitation(
        id: 'murattal_002',
        surahNumber: 2,
        surahNameAr: 'البقرة',
        surahNameEn: 'Al-Baqarah',
        verseRange: '1-286',
        durationSeconds: 7200,
        fileSizeBytes: 50000000,
        audioUrl: 'https://server10.mp3quran.net/minsh/002.mp3',
        recordingYear: 'المصحف المرتل',
        recordingLocation: 'القاهرة',
        collectionId: 'complete_murattal',
        quality: 'مرتل عالي الجودة',
        isRare: false,
      ),
      const Recitation(
        id: 'murattal_018',
        surahNumber: 18,
        surahNameAr: 'الكهف',
        surahNameEn: 'Al-Kahf',
        verseRange: '1-110',
        durationSeconds: 1800,
        fileSizeBytes: 20000000,
        audioUrl: 'https://server10.mp3quran.net/minsh/018.mp3',
        recordingYear: 'المصحف المرتل',
        recordingLocation: 'القاهرة',
        collectionId: 'complete_murattal',
        quality: 'مرتل عالي الجودة',
        isRare: false,
      ),
    ];

    test('searches by Arabic name with variations', () {
      final state1 = RecitationListLoaded(
        recitations: sampleRecitations,
        searchQuery: 'البقره',
      );
      expect(state1.filtered.length, equals(1));
      expect(state1.filtered.first.surahNumber, equals(2));

      final state2 = RecitationListLoaded(
        recitations: sampleRecitations,
        searchQuery: 'كهف',
      );
      expect(state2.filtered.length, equals(1));
      expect(state2.filtered.first.surahNumber, equals(18));
    });

    test('searches by Arabic digits', () {
      final state = RecitationListLoaded(
        recitations: sampleRecitations,
        searchQuery: '١٨',
      );
      expect(state.filtered.length, equals(1));
      expect(state.filtered.first.surahNumber, equals(18));
    });

    test('searches by English name', () {
      final state = RecitationListLoaded(
        recitations: sampleRecitations,
        searchQuery: 'kahf',
      );
      expect(state.filtered.length, equals(1));
      expect(state.filtered.first.surahNumber, equals(18));
    });
  });
}
