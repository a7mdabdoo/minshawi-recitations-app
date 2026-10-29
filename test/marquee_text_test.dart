import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:al_minshawi_recitations/core/widgets/marquee_text.dart';

void main() {
  testWidgets('MarqueeText renders static text without animation when it fits',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: MarqueeText(
              text: 'نص قصير',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ),
    );

    expect(find.text('نص قصير'), findsOneWidget);
    // Let any post frame callbacks execute
    await tester.pump();
  });

  testWidgets('MarqueeText handles empty text cleanly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: MarqueeText(text: ''),
          ),
        ),
      ),
    );

    expect(find.byType(MarqueeText), findsOneWidget);
  });

  testWidgets('MarqueeText renders scrollable text when overflowing',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 80,
            child: MarqueeText(
              text: 'هذا نص تجريبي طويل جداً لتجربة التمرير الأفقي في التطبيق',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);

    // Dispose properly without pending timers
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
