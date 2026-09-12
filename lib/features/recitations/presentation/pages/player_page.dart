import 'package:flutter/material.dart';
import 'package:al_minshawi_recitations/features/player/presentation/pages/audio_player_screen.dart';

export 'package:al_minshawi_recitations/features/player/presentation/pages/audio_player_screen.dart';

/// Full-screen audio player page wrapper for routing.
class PlayerPage extends StatelessWidget {
  final String? initialRecitationId;

  const PlayerPage({super.key, this.initialRecitationId});

  @override
  Widget build(BuildContext context) {
    return AudioPlayerScreen(initialRecitationId: initialRecitationId);
  }
}
