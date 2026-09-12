import 'package:flutter_test/flutter_test.dart';
import 'package:al_minshawi_recitations/features/player/presentation/cubit/audio_player_state.dart';
import 'package:al_minshawi_recitations/features/recitations/domain/entities/recitation.dart';

void main() {
  const dummyRecitation = Recitation(
    id: '001',
    surahNumber: 1,
    surahNameAr: 'الفاتحة',
    surahNameEn: 'Al-Fatihah',
    verseRange: '1-7',
    audioUrl: 'https://example.com/001.mp3',
    durationSeconds: 120,
    fileSizeBytes: 1024,
    recordingYear: '1960',
    recordingLocation: 'القاهرة',
    collectionId: 'complete_murattal',
    isRare: false,
    quality: 'HQ',
  );

  test('AudioPlayerReady abLoopState transitions correctly', () {
    const state0 = AudioPlayerReady(
      recitation: dummyRecitation,
      position: Duration.zero,
      duration: Duration(seconds: 120),
      isPlaying: false,
    );
    expect(state0.abLoopState, equals(AbLoopState.off));
    expect(state0.isAbLoopActive, isFalse);

    final state1 = state0.copyWith(
      abPointA: const Duration(seconds: 15),
    );
    expect(state1.abLoopState, equals(AbLoopState.pointASet));
    expect(state1.isAbLoopActive, isFalse);

    final state2 = state1.copyWith(
      abPointB: const Duration(seconds: 35),
    );
    expect(state2.abLoopState, equals(AbLoopState.active));
    expect(state2.isAbLoopActive, isTrue);

    final state3 = state2.copyWith(clearAbPoints: true);
    expect(state3.abLoopState, equals(AbLoopState.off));
    expect(state3.abPointA, isNull);
    expect(state3.abPointB, isNull);
    expect(state3.isAbLoopActive, isFalse);
  });

  test('Point A is preserved across seek and buffering state updates', () {
    const initial = AudioPlayerReady(
      recitation: dummyRecitation,
      position: Duration.zero,
      duration: Duration(seconds: 120),
      isPlaying: true,
      abPointA: Duration(seconds: 15),
    );
    expect(initial.abLoopState, equals(AbLoopState.pointASet));

    final sought = initial.copyWith(position: const Duration(seconds: 25));
    expect(sought.abLoopState, equals(AbLoopState.pointASet));
    expect(sought.abPointA, equals(const Duration(seconds: 15)));

    final buffering = sought.copyWith(isBuffering: true);
    expect(buffering.abLoopState, equals(AbLoopState.pointASet));
    expect(buffering.abPointA, equals(const Duration(seconds: 15)));
  });
}
