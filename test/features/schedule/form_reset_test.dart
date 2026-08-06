import 'package:ai_calendar/app.dart';
import 'package:ai_calendar/features/ai/ai_providers.dart';
import 'package:ai_calendar/features/ai/service/ai_provider_store.dart';
import 'package:ai_calendar/features/ai/service/ai_service.dart';
import 'package:ai_calendar/features/schedule/model/schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAiService extends AiService {
  _FakeAiService() : super(client: http.Client(), store: AiProviderStore());

  @override
  Future<Schedule> parse(String naturalLanguage, {DateTime? now}) async {
    return Schedule(
      title: '解析出的标题',
      start: DateTime(2026, 8, 6, 15),
      end: DateTime(2026, 8, 6, 17),
    );
  }
}

TextField _textField(WidgetTester tester, String label) {
  return tester.widget<TextField>(
    find.ancestor(
      of: find.text(label),
      matching: find.byType(TextField),
    ).first,
  );
}

String _textOf(WidgetTester tester, String label) {
  return _textField(tester, label).controller?.text ?? '';
}

void main() {
  testWidgets('重置表单应清空所有输入', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiServiceProvider.overrideWithValue(_FakeAiService()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 填入各类输入
    await tester.enterText(find.byType(TextField).first, '明天下午三点开会');
    await tester.enterText(
      find.ancestor(
        of: find.text('标题'),
        matching: find.byType(TextField),
      ),
      '项目评审会',
    );
    await tester.enterText(
      find.ancestor(
        of: find.text('描述'),
        matching: find.byType(TextField),
      ),
      '评审 v1.2',
    );
    // 切换提醒和重复
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '不提醒'));
    await tester.tap(find.widgetWithText(ChoiceChip, '不提醒'));
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '每周'));
    await tester.tap(find.widgetWithText(ChoiceChip, '每周'));
    await tester.pumpAndSettle();

    expect(find.text('一'), findsOneWidget);

    // 点击重置
    await tester.tap(find.byTooltip('重置表单'));
    await tester.pumpAndSettle();

    // AI 输入框应被清空
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      isEmpty,
      reason: 'AI 输入框应随重置清空',
    );
    // 标题、描述应被清空
    expect(_textOf(tester, '标题'), isEmpty, reason: '标题应随重置清空');
    expect(_textOf(tester, '描述'), isEmpty, reason: '描述应随重置清空');
    // 提醒应回到默认 15 分钟前
    final reminderChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '15 分钟前'),
    );
    expect(reminderChip.selected, isTrue, reason: '提醒应回到默认 15 分钟前');
    // 重复应回到不重复，周选择器隐藏
    final repeatChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '不重复'),
    );
    expect(repeatChip.selected, isTrue, reason: '重复应回到不重复');
    expect(find.text('一'), findsNothing, reason: '周选择器应随重置隐藏');
  });
}
