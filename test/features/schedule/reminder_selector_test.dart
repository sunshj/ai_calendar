import 'package:ai_calendar/features/schedule/widgets/reminder_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ReminderSelector 支持"开始时提醒"与"不提醒"', (tester) async {
    int? selected = 15;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReminderSelector(
            valueMinutes: selected,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.text('开始时'), findsOneWidget);
    expect(find.text('不提醒'), findsOneWidget);

    await tester.tap(find.text('开始时'));
    expect(selected, 0);

    await tester.tap(find.text('不提醒'));
    expect(selected, isNull);
  });
}
