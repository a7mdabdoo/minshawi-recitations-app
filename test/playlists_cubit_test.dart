import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:al_minshawi_recitations/core/constants/app_constants.dart';
import 'package:al_minshawi_recitations/features/playlists/presentation/cubit/playlists_cubit.dart';
import 'package:al_minshawi_recitations/features/playlists/presentation/cubit/playlists_state.dart';
import 'package:al_minshawi_recitations/features/recitations/domain/entities/recitation.dart';

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

  test('createPlaylist with full Recitation entity persists metadata and recitations', () async {
    const recitation = Recitation(
      id: '055',
      surahNumber: 55,
      surahNameAr: 'الرحمن',
      surahNameEn: 'Ar-Rahman',
      verseRange: '1-78',
      durationSeconds: 1200,
      fileSizeBytes: 15000000,
      audioUrl: 'https://example.com/055.mp3',
      recordingYear: '1387 هـ',
      recordingLocation: 'القاهرة',
      isRare: true,
      quality: 'HQ',
    );

    final p = await cubit.createPlaylist('روائع التلاوات', initialRecitation: recitation);

    expect(p.name, equals('روائع التلاوات'));
    expect(p.recitationIds, contains('055'));
    expect(p.recitations.length, equals(1));
    expect(p.recitations.first.surahNameAr, equals('الرحمن'));

    // Check loaded state
    final state = cubit.state as PlaylistsLoaded;
    final loaded = state.getPlaylist(p.id)!;
    expect(loaded.recitations.length, equals(1));
    expect(loaded.recitations.first.surahNameAr, equals('الرحمن'));
  });

  test('addRecitationToPlaylist with Recitation entity stores full object', () async {
    final p = await cubit.createPlaylist('تلاوات المساء');
    const recitation = Recitation(
      id: '056',
      surahNumber: 56,
      surahNameAr: 'الواقعة',
      surahNameEn: 'Al-Waqi\'ah',
      verseRange: '1-96',
      durationSeconds: 900,
      fileSizeBytes: 10000000,
      audioUrl: 'https://example.com/056.mp3',
      recordingYear: '1387 هـ',
      recordingLocation: 'دمشق',
      isRare: true,
      quality: 'HQ',
    );

    final added = await cubit.addRecitationToPlaylist(p.id, recitation.id, recitation);
    expect(added, isTrue);

    final state = cubit.state as PlaylistsLoaded;
    final loaded = state.getPlaylist(p.id)!;
    expect(loaded.recitationIds, contains('056'));
    expect(loaded.recitations.length, equals(1));
    expect(loaded.recitations.first.surahNameAr, equals('الواقعة'));
  });

  test('toggleRecitationInPlaylist toggles presence and keeps recitations list in sync', () async {
    final p = await cubit.createPlaylist('قائمة التجربة');
    const recitation = Recitation(
      id: '018',
      surahNumber: 18,
      surahNameAr: 'الكهف',
      surahNameEn: 'Al-Kahf',
      verseRange: '1-110',
      durationSeconds: 1800,
      fileSizeBytes: 20000000,
      audioUrl: 'https://example.com/018.mp3',
      recordingYear: '1387 هـ',
      recordingLocation: 'الكويت',
      isRare: true,
      quality: 'HQ',
    );

    // Toggle ON
    await cubit.toggleRecitationInPlaylist(p.id, recitation.id, recitation);
    var loaded = (cubit.state as PlaylistsLoaded).getPlaylist(p.id)!;
    expect(loaded.recitationIds, contains('018'));
    expect(loaded.recitations.any((r) => r.id == '018'), isTrue);

    // Toggle OFF
    await cubit.toggleRecitationInPlaylist(p.id, recitation.id, recitation);
    loaded = (cubit.state as PlaylistsLoaded).getPlaylist(p.id)!;
    expect(loaded.recitationIds, isNot(contains('018')));
    expect(loaded.recitations.any((r) => r.id == '018'), isFalse);
  });
}
