import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:al_minshawi_recitations/core/constants/app_constants.dart';
import 'package:al_minshawi_recitations/features/playlists/presentation/cubit/playlists_cubit.dart';
import 'package:al_minshawi_recitations/features/playlists/presentation/cubit/playlists_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<dynamic> box;
  late PlaylistsCubit cubit;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_playlists');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>(AppConstants.playlistsBoxName);
    cubit = PlaylistsCubit(box);
  });

  tearDown(() async {
    await cubit.close();
    await box.close();
    await Hive.deleteBoxFromDisk(AppConstants.playlistsBoxName);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('Initial state is PlaylistsLoaded with empty list if box is empty', () {
    expect(cubit.state, isA<PlaylistsLoaded>());
    expect((cubit.state as PlaylistsLoaded).playlists, isEmpty);
  });

  test('createPlaylist creates new playlist and saves to Hive', () async {
    final playlist = await cubit.createPlaylist('تلاوات الفجر');

    expect(playlist.title, equals('تلاوات الفجر'));
    expect(playlist.recitationIds, isEmpty);

    final state = cubit.state as PlaylistsLoaded;
    expect(state.playlists.length, equals(1));
    expect(state.playlists.first.title, equals('تلاوات الفجر'));
  });

  test('createPlaylist with initialRecitationId includes it immediately', () async {
    final playlist = await cubit.createPlaylist('خواتيم السور', initialRecitationId: '002');

    expect(playlist.recitationIds, contains('002'));
    final state = cubit.state as PlaylistsLoaded;
    expect(state.playlists.first.recitationIds, contains('002'));
  });

  test('addRecitationToPlaylist and removeRecitationFromPlaylist modify recitations', () async {
    final p = await cubit.createPlaylist('المفضلة النادرة');

    // Add recitation
    final added = await cubit.addRecitationToPlaylist(p.id, '001');
    expect(added, isTrue);
    expect((cubit.state as PlaylistsLoaded).getPlaylist(p.id)!.recitationIds, contains('001'));

    // Duplicate add should be ignored
    final addedAgain = await cubit.addRecitationToPlaylist(p.id, '001');
    expect(addedAgain, isFalse);

    // Remove recitation
    final removed = await cubit.removeRecitationFromPlaylist(p.id, '001');
    expect(removed, isTrue);
    expect((cubit.state as PlaylistsLoaded).getPlaylist(p.id)!.recitationIds, isNot(contains('001')));
  });

  test('renamePlaylist updates playlist title in state and storage', () async {
    final p = await cubit.createPlaylist('اسم قديم');
    await cubit.renamePlaylist(p.id, 'اسم جديد ومميز');

    final updated = (cubit.state as PlaylistsLoaded).getPlaylist(p.id);
    expect(updated?.title, equals('اسم جديد ومميز'));
  });

  test('deletePlaylist removes playlist from Hive and emits updated list', () async {
    final p1 = await cubit.createPlaylist('قائمة 1');
    final p2 = await cubit.createPlaylist('قائمة 2');

    expect((cubit.state as PlaylistsLoaded).playlists.length, equals(2));

    await cubit.deletePlaylist(p1.id);

    final state = cubit.state as PlaylistsLoaded;
    expect(state.playlists.length, equals(1));
    expect(state.getPlaylist(p1.id), isNull);
    expect(state.getPlaylist(p2.id), isNotNull);
  });
}
