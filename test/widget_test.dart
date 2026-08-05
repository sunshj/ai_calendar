import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ai_calendar/app.dart';

void main() {
  testWidgets('App should build and show AI Calendar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI Calendar'), findsOneWidget);
  });
}
