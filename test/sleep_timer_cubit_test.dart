import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:al_minshawi_recitations/features/player/presentation/cubit/audio_player_cubit.dart';
import 'package:al_minshawi_recitations/features/player/presentation/cubit/sleep_timer_cubit.dart';
import 'package:al_minshawi_recitations/features/player/presentation/cubit/sleep_timer_state.dart';
import 'package:al_minshawi_recitations/features/recitations/data/datasources/local_recitation_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Box<dynamic> box;
  late AudioPlayerCubit audioPlayerCubit;
  late SleepTimerCubit sleepTimerCubit;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sleep_timer_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('test_downloaded_box');
    audioPlayerCubit = AudioPlayerCubit(LocalRecitationDataSource(box));
    sleepTimerCubit = SleepTimerCubit(audioPlayerCubit);
  });

  tearDown(() async {
    await sleepTimerCubit.close();
    await audioPlayerCubit.close();
    await box.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('Initial state is inactive', () {
    expect(sleepTimerCubit.state.isActive, isFalse);
    expect(sleepTimerCubit.state.mode, equals(SleepTimerMode.inactive));
    expect(sleepTimerCubit.state.remainingTime, isNull);
  });

  test('startTimer activates duration timer and updates remaining time', () async {
    sleepTimerCubit.startTimer(const Duration(minutes: 15), '١٥ دقيقة');

    expect(sleepTimerCubit.state.isActive, isTrue);
    expect(sleepTimerCubit.state.mode, equals(SleepTimerMode.duration));
    expect(sleepTimerCubit.state.remainingTime, equals(const Duration(minutes: 15)));
    expect(sleepTimerCubit.state.selectedOptionLabel, equals('١٥ دقيقة'));

    sleepTimerCubit.cancelTimer();
    expect(sleepTimerCubit.state.isActive, isFalse);
    expect(sleepTimerCubit.state.mode, equals(SleepTimerMode.inactive));
  });

  test('setTimerEndOfSurah activates end-of-surah mode', () {
    sleepTimerCubit.setTimerEndOfSurah(label: 'عند نهاية السورة');

    expect(sleepTimerCubit.state.isActive, isTrue);
    expect(sleepTimerCubit.state.isEndOfSurah, isTrue);
    expect(sleepTimerCubit.state.mode, equals(SleepTimerMode.endOfSurah));
    expect(sleepTimerCubit.state.selectedOptionLabel, equals('عند نهاية السورة'));

    sleepTimerCubit.cancelTimer();
    expect(sleepTimerCubit.state.isActive, isFalse);
  });
}
