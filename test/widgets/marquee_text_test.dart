import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:al_minshawi_recitations/core/widgets/marquee_text.dart';

void main() {
  testWidgets('MarqueeText renders short text without scroll view', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: MarqueeText(text: 'سورة الفاتحة'),
          ),
        ),
      ),
    );

    expect(find.text('سورة الفاتحة'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  testWidgets('MarqueeText renders SingleChildScrollView and animates when text overflows', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: 80,
              child: MarqueeText(
                text: 'سورة الحشر والطارق والفجر والشمس والضحى المباركة',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('سورة الحشر والطارق والفجر والشمس والضحى المباركة'), findsOneWidget);

    // Fast-forward past pauseDuration to trigger animation
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 1000));

    // Dispose safely without pending timer issues
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
