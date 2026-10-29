import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:al_minshawi_recitations/core/theme/theme_cubit.dart';
import 'package:al_minshawi_recitations/features/player/presentation/cubit/audio_player_cubit.dart';
import 'package:al_minshawi_recitations/features/player/presentation/cubit/audio_player_state.dart';
import 'package:al_minshawi_recitations/features/playlists/presentation/cubit/playlists_cubit.dart';
import 'package:al_minshawi_recitations/features/playlists/presentation/cubit/playlists_state.dart';
import 'package:al_minshawi_recitations/features/recitations/presentation/pages/landing_page.dart';

class _MockAudioPlayerCubit extends Cubit<AudioPlayerState>
    implements AudioPlayerCubit {
  _MockAudioPlayerCubit() : super(const AudioPlayerIdle());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockPlaylistsCubit extends Cubit<PlaylistsState>
    implements PlaylistsCubit {
  _MockPlaylistsCubit() : super(const PlaylistsLoaded(playlists: []));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockThemeCubit extends Cubit<ThemeMode> implements ThemeCubit {
  _MockThemeCubit() : super(ThemeMode.dark);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('LandingPage scroll test', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AudioPlayerCubit>.value(value: _MockAudioPlayerCubit()),
          BlocProvider<PlaylistsCubit>.value(value: _MockPlaylistsCubit()),
          BlocProvider<ThemeCubit>.value(value: _MockThemeCubit()),
        ],
        child: const MaterialApp(
          home: LandingPage(),
        ),
      ),
    );

    await tester.pump();
    // Try scrolling up
    await tester.drag(find.byType(LandingPage), const Offset(0, -300));
    await tester.pump();
  });
}
