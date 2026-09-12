import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:al_minshawi_recitations/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:al_minshawi_recitations/features/favorites/presentation/cubit/favorites_state.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late FavoritesCubit cubit;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('test_favorites_box');
    cubit = FavoritesCubit(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('Initial state is empty or loaded from box', () {
    expect(cubit.state, isA<FavoritesLoaded>());
    expect(cubit.state.favoriteIds, isEmpty);
    expect(cubit.isFavorite('rare_1387_001'), isFalse);
  });

  test('toggleFavorite adds and removes items properly', () async {
    await cubit.toggleFavorite('rare_1387_001');
    expect(cubit.isFavorite('rare_1387_001'), isTrue);
    expect(cubit.state.favoriteIds.contains('rare_1387_001'), isTrue);

    await cubit.toggleFavorite('murattal_002');
    expect(cubit.isFavorite('murattal_002'), isTrue);
    expect(cubit.state.favoriteIds.length, equals(2));

    await cubit.toggleFavorite('rare_1387_001');
    expect(cubit.isFavorite('rare_1387_001'), isFalse);
    expect(cubit.state.favoriteIds.length, equals(1));
  });
}
