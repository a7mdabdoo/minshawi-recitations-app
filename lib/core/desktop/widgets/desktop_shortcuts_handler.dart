import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/player/presentation/cubit/audio_player_cubit.dart';

class DesktopShortcutsHandler extends StatelessWidget {
  final Widget child;

  const DesktopShortcutsHandler({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        final primaryFocus = FocusManager.instance.primaryFocus;
        if (primaryFocus != null &&
            primaryFocus.context != null &&
            primaryFocus.context!.widget is EditableText) {
          return KeyEventResult.ignored;
        }

        final cubit = context.read<AudioPlayerCubit>();

        if (event.logicalKey == LogicalKeyboardKey.space) {
          cubit.togglePlayPause();
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          cubit.skipBackward();
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          cubit.skipForward();
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          final newVol = (cubit.volume + 0.1).clamp(0.0, 1.0);
          cubit.setVolume(newVol);
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          final newVol = (cubit.volume - 0.1).clamp(0.0, 1.0);
          cubit.setVolume(newVol);
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
