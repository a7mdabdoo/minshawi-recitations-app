import 'package:flutter_test/flutter_test.dart';
import 'package:al_minshawi_recitations/features/recitations/domain/entities/recitation.dart';

void main() {
  group('Recitation Title and Location separation tests', () {
    test('Separates concert title with dash into pure Surah name and location', () {
      const recitation = Recitation(
        id: '1',
        surahNumber: 19,
        surahNameAr: 'مريم - المسجد الأقصى 1964',
        surahNameEn: 'Maryam',
        verseRange: '',
        durationSeconds: 2400,
        fileSizeBytes: 1000,
        audioUrl: 'http://example.com/audio.mp3',
        recordingYear: '1964',
        recordingLocation: 'المسجد الأقصى (1964)',
        isRare: true,
        quality: 'High',
      );

      expect(recitation.cleanSurahTitleWithVerses, 'سورة مريم');
      expect(recitation.cleanLocationOrDetail, 'المسجد الأقصى 1964');
    });

    test('Includes numeric verse range in Surah title line', () {
      const recitation = Recitation(
        id: '2',
        surahNumber: 1,
        surahNameAr: 'الفاتحة',
        surahNameEn: 'Al-Fatihah',
        verseRange: '1-7',
        durationSeconds: 50,
        fileSizeBytes: 1000,
        audioUrl: 'http://example.com/audio.mp3',
        recordingYear: '',
        recordingLocation: '',
        collectionId: 'complete_murattal',
        isRare: false,
        quality: 'High',
      );

      expect(recitation.cleanSurahTitleWithVerses, 'سورة الفاتحة (الآيات: 1-7)');
      expect(recitation.cleanLocationOrDetail, 'المصحف المرتل');
    });

    test('Handles combined Surahs title correctly', () {
      const recitation = Recitation(
        id: '3',
        surahNumber: 59,
        surahNameAr: 'الحشر والطارق والفجر والعلق - ستينات الإسكندرية',
        surahNameEn: 'Al-Hashr & others',
        verseRange: '',
        durationSeconds: 1800,
        fileSizeBytes: 1000,
        audioUrl: 'http://example.com/audio.mp3',
        recordingYear: '1960',
        recordingLocation: 'ستينات الإسكندرية',
        isRare: true,
        quality: 'High',
      );

      expect(recitation.cleanSurahTitleWithVerses, 'سورة الحشر والطارق والفجر والعلق');
      expect(recitation.cleanLocationOrDetail, 'ستينات الإسكندرية');
    });
  });
}
