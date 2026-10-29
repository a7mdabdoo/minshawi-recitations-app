import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:al_minshawi_recitations/core/theme/theme_cubit.dart';
import 'package:al_minshawi_recitations/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:al_minshawi_recitations/features/favorites/presentation/cubit/favorites_state.dart';
import 'package:al_minshawi_recitations/features/player/presentation/cubit/audio_player_cubit.dart';
import 'package:al_minshawi_recitations/features/player/presentation/cubit/audio_player_state.dart';
import 'package:al_minshawi_recitations/features/player/presentation/cubit/sleep_timer_cubit.dart';
import 'package:al_minshawi_recitations/features/player/presentation/cubit/sleep_timer_state.dart';
import 'package:al_minshawi_recitations/features/player/presentation/pages/audio_player_screen.dart';
import 'package:al_minshawi_recitations/features/playlists/presentation/cubit/playlists_cubit.dart';
import 'package:al_minshawi_recitations/features/playlists/presentation/cubit/playlists_state.dart';
import 'package:al_minshawi_recitations/features/recitations/domain/entities/recitation.dart';
import 'package:al_minshawi_recitations/features/recitations/presentation/cubit/download_cubit.dart';
import 'package:al_minshawi_recitations/features/recitations/presentation/cubit/download_state.dart';
import 'package:al_minshawi_recitations/features/recitations/presentation/cubit/nahawand_cubit.dart';
import 'package:al_minshawi_recitations/features/recitations/presentation/cubit/nahawand_state.dart';
import 'package:al_minshawi_recitations/features/recitations/presentation/cubit/recitation_list_cubit.dart';
import 'package:al_minshawi_recitations/features/recitations/presentation/cubit/recitation_list_state.dart';

class _FakeAudioPlayerCubit extends Cubit<AudioPlayerState>
    implements AudioPlayerCubit {
  _FakeAudioPlayerCubit()
      : super(
          const AudioPlayerReady(
            isPlaying: true,
            recitation: Recitation(
              id: 'test_1',
              surahNumber: 1,
              surahNameAr: 'الفاتحة',
              surahNameEn: 'Al-Fatihah',
              verseRange: '1-7',
              durationSeconds: 180,
              fileSizeBytes: 2000000,
              audioUrl: 'https://example.com/1.mp3',
              recordingYear: '1964',
              recordingLocation: 'مسجد لالا مصطفى باشا - دمشق',
              collectionId: 'nahawand',
              isRare: false,
              quality: 'عالية',
            ),
            position: Duration(seconds: 30),
            duration: Duration(seconds: 180),
          ),
        );

  bool _shuffle = false;
  @override
  bool get isShuffleEnabled => _shuffle;

  @override
  void toggleShuffle() {
    _shuffle = !_shuffle;
    final s = state;
    if (s is AudioPlayerReady) {
      emit(s.copyWith(isShuffleEnabled: _shuffle));
    }
  }

  @override
  double get volume => 1.0;

  @override
  Recitation? get currentRecitation => state is AudioPlayerReady
      ? (state as AudioPlayerReady).recitation
      : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFavoritesCubit extends Cubit<FavoritesState>
    implements FavoritesCubit {
  _FakeFavoritesCubit() : super(const FavoritesInitial());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSleepTimerCubit extends Cubit<SleepTimerState>
    implements SleepTimerCubit {
  _FakeSleepTimerCubit() : super(SleepTimerState.initial);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRecitationListCubit extends Cubit<RecitationListState>
    implements RecitationListCubit {
  _FakeRecitationListCubit() : super(const RecitationListInitial());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNahawandCubit extends Cubit<NahawandState> implements NahawandCubit {
  _FakeNahawandCubit() : super(const NahawandInitial());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDownloadCubit extends Cubit<DownloadState> implements DownloadCubit {
  _FakeDownloadCubit() : super(const DownloadState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePlaylistsCubit extends Cubit<PlaylistsState>
    implements PlaylistsCubit {
  _FakePlaylistsCubit() : super(const PlaylistsLoaded(playlists: []));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeThemeCubit extends Cubit<ThemeMode> implements ThemeCubit {
  _FakeThemeCubit() : super(ThemeMode.dark);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('AudioPlayerScreen layout and scroll test', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AudioPlayerCubit>.value(value: _FakeAudioPlayerCubit()),
          BlocProvider<FavoritesCubit>.value(value: _FakeFavoritesCubit()),
          BlocProvider<SleepTimerCubit>.value(value: _FakeSleepTimerCubit()),
          BlocProvider<RecitationListCubit>.value(
              value: _FakeRecitationListCubit()),
          BlocProvider<NahawandCubit>.value(value: _FakeNahawandCubit()),
          BlocProvider<DownloadCubit>.value(value: _FakeDownloadCubit()),
          BlocProvider<PlaylistsCubit>.value(value: _FakePlaylistsCubit()),
          BlocProvider<ThemeCubit>.value(value: _FakeThemeCubit()),
        ],
        child: const MaterialApp(
          home: AudioPlayerScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(AudioPlayerScreen), findsOneWidget);

    // Tap shuffle button on first tap and verify it activates immediately
    expect(find.byTooltip('التشغيل العشوائي: معطّل'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.shuffle_rounded));
    await tester.pump();
    expect(find.byTooltip('التشغيل العشوائي: مفعّل'), findsOneWidget);

    // Try scrolling up
    await tester.drag(find.byType(AudioPlayerScreen), const Offset(0, -300));
    await tester.pump();
  });
}
