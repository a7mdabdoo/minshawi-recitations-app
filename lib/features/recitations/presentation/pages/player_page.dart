import 'package:flutter/material.dart';

/// Player page – Full implementation in Phase 5.
/// Phase 1 provides a skeleton so routing compiles.
class PlayerPage extends StatelessWidget {
  final String? initialRecitationId;

  const PlayerPage({super.key, this.initialRecitationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المشغّل'),

        centerTitle: true,
      ),
      body: Center(
        child: Text('تلاوة: ${initialRecitationId ?? 'غير محدد'}'),
      ),
    );
  }
}
