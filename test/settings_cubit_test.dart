import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:al_minshawi_recitations/core/settings/settings_cubit.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late SettingsCubit cubit;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_settings_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('test_settings_box');
    cubit = SettingsCubit(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('Initial state is empty', () {
    expect(cubit.state.lastPlayedRecitationId, isNull);
    expect(cubit.state.lastPlayedPositionSeconds, isNull);
  });

  test('saveLastPlayed persists recitationId and position in seconds', () async {
    await cubit.saveLastPlayed(
      recitationId: 'rare_1387_002',
      positionSeconds: 145,
    );

    expect(cubit.state.lastPlayedRecitationId, equals('rare_1387_002'));
    expect(cubit.state.lastPlayedPositionSeconds, equals(145));

    final newCubit = SettingsCubit(box);
    expect(newCubit.state.lastPlayedRecitationId, equals('rare_1387_002'));
    expect(newCubit.state.lastPlayedPositionSeconds, equals(145));
  });

  test('clearLastPlayed removes stored values', () async {
    await cubit.saveLastPlayed(
      recitationId: 'rare_1387_002',
      positionSeconds: 145,
    );

    await cubit.clearLastPlayed();

    expect(cubit.state.lastPlayedRecitationId, isNull);
    expect(cubit.state.lastPlayedPositionSeconds, isNull);
  });
}
