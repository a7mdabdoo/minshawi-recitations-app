import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:al_minshawi_recitations/core/constants/app_constants.dart';
import 'package:al_minshawi_recitations/features/player/presentation/cubit/audio_player_cubit.dart';
import 'package:al_minshawi_recitations/features/player/presentation/cubit/audio_player_state.dart';
import 'package:al_minshawi_recitations/features/playlists/presentation/cubit/playlists_cubit.dart';
import 'package:al_minshawi_recitations/features/playlists/presentation/pages/playlists_page.dart';
import 'package:al_minshawi_recitations/features/recitations/domain/entities/recitation.dart';
import 'package:al_minshawi_recitations/features/recitations/presentation/cubit/recitation_list_cubit.dart';
import 'package:al_minshawi_recitations/features/recitations/presentation/cubit/recitation_list_state.dart';

class _FakeAudioPlayerCubit extends Cubit<AudioPlayerState> implements AudioPlayerCubit {
  _FakeAudioPlayerCubit() : super(const AudioPlayerIdle());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRecitationListCubit extends Cubit<RecitationListState> implements RecitationListCubit {
  _FakeRecitationListCubit() : super(const RecitationListLoaded(recitations: []));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<dynamic> box;
  late PlaylistsCubit playlistsCubit;
  late _FakeAudioPlayerCubit audioPlayerCubit;
  late _FakeRecitationListCubit recitationListCubit;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_ui_playlists');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>(AppConstants.playlistsBoxName);
    playlistsCubit = PlaylistsCubit(box);
    audioPlayerCubit = _FakeAudioPlayerCubit();
    recitationListCubit = _FakeRecitationListCubit();
  });

  tearDown(() async {
    await playlistsCubit.close();
    await audioPlayerCubit.close();
    await recitationListCubit.close();
    await box.close();
    await Hive.deleteBoxFromDisk(AppConstants.playlistsBoxName);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<PlaylistsCubit>.value(value: playlistsCubit),
          BlocProvider<AudioPlayerCubit>.value(value: audioPlayerCubit),
          BlocProvider<RecitationListCubit>.value(value: recitationListCubit),
        ],
        child: const PlaylistsPage(),
      ),
    );
  }

  testWidgets('Renders empty state cleanly when no playlists exist', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('لا توجد قوائم تشغيل مخصصة'), findsOneWidget);
    expect(find.text('إنشاء قائمة جديدة'), findsOneWidget);
  });

  testWidgets('Renders playlists and filters safely using search bar', (tester) async {
    const recitation1 = Recitation(
      id: '001',
      surahNumber: 1,
      surahNameAr: 'الفاتحة',
      surahNameEn: 'Al-Fatihah',
      verseRange: '1-7',
      durationSeconds: 60,
      fileSizeBytes: 1000,
      audioUrl: 'https://example.com/1.mp3',
      recordingYear: '1387',
      recordingLocation: 'مصر',
      isRare: true,
      quality: 'HQ',
    );

    const recitation2 = Recitation(
      id: '002',
      surahNumber: 2,
      surahNameAr: 'البقرة',
      surahNameEn: 'Al-Baqarah',
      verseRange: '1-286',
      durationSeconds: 7200,
      fileSizeBytes: 10000,
      audioUrl: 'https://example.com/2.mp3',
      recordingYear: '1387',
      recordingLocation: 'مصر',
      isRare: true,
      quality: 'HQ',
    );

    await playlistsCubit.createPlaylist('تلاوات خاشعة', initialRecitation: recitation1);
    await playlistsCubit.createPlaylist('المصحف المرتل', initialRecitation: recitation2);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify both are present initially
    expect(find.text('تلاوات خاشعة'), findsOneWidget);
    expect(find.text('المصحف المرتل'), findsOneWidget);

    // Search by playlist name
    await tester.enterText(find.byType(TextField).first, 'خاشعة');
    await tester.pumpAndSettle();

    expect(find.text('تلاوات خاشعة'), findsOneWidget);
    expect(find.text('المصحف المرتل'), findsNothing);

    // Search by contained surah name ('البقرة')
    await tester.enterText(find.byType(TextField).first, 'البقرة');
    await tester.pumpAndSettle();

    expect(find.text('المصحف المرتل'), findsOneWidget);
    expect(find.text('تلاوات خاشعة'), findsNothing);

    // Search with non-matching query displays empty search results view
    await tester.enterText(find.byType(TextField).first, 'سورة_غير_موجودة');
    await tester.pumpAndSettle();

    expect(find.text('لم يتم العثور على نتائج'), findsOneWidget);
    expect(find.text('مسح البحث'), findsOneWidget);

    // Tap clear search button
    await tester.tap(find.text('مسح البحث'));
    await tester.pumpAndSettle();

    expect(find.text('تلاوات خاشعة'), findsOneWidget);
    expect(find.text('المصحف المرتل'), findsOneWidget);
  });
}
