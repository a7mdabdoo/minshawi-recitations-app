import 'package:flutter_test/flutter_test.dart';
import 'package:al_minshawi_recitations/features/recitations/domain/entities/recitation.dart';
import 'package:al_minshawi_recitations/features/recitations/presentation/cubit/recitation_list_state.dart';

void main() {
  group('Multi-token Search Tests', () {
    const r1 = Recitation(
      id: 'rare_1',
      surahNumber: 12,
      surahNameAr: 'يوسف - مسجد لالا مصطفى باشا 1958',
      surahNameEn: 'Yusuf',
      verseRange: '1-30',
      durationSeconds: 1800,
      fileSizeBytes: 10000,
      audioUrl: 'http://example.com/yusuf.mp3',
      recordingYear: '1958',
      recordingLocation: 'مسجد لالا مصطفى باشا - دمشق',
      isRare: true,
      quality: 'High',
    );

    const r2 = Recitation(
      id: 'rare_2',
      surahNumber: 19,
      surahNameAr: 'مريم - تسجيل ليبيا 1964',
      surahNameEn: 'Maryam',
      verseRange: '1-36',
      durationSeconds: 2400,
      fileSizeBytes: 15000,
      audioUrl: 'http://example.com/maryam.mp3',
      recordingYear: '1964',
      recordingLocation: 'تسجيل ليبيا (1964)',
      isRare: true,
      quality: 'High',
    );

    const state = RecitationListLoaded(
      recitations: [r1, r2],
    );

    test('Searches by "سورة يوسف مسجد لالا"', () {
      final filtered = state.copyWith(searchQuery: 'سورة يوسف مسجد لالا').filtered;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'rare_1');
    });

    test('Searches by "سورة مريم تسجيل ليبيا 1964"', () {
      final filtered = state.copyWith(searchQuery: 'سورة مريم تسجيل ليبيا 1964').filtered;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'rare_2');
    });

    test('Searches by partial place "ليبيا 1964"', () {
      final filtered = state.copyWith(searchQuery: 'ليبيا 1964').filtered;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'rare_2');
    });

    test('Searches by surah name and year "يوسف 1958"', () {
      final filtered = state.copyWith(searchQuery: 'يوسف 1958').filtered;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'rare_1');
    });
  });
}
