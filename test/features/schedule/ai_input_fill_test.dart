import 'dart:async';

import 'package:ai_calendar/app.dart';
import 'package:ai_calendar/features/ai/ai_providers.dart';
import 'package:ai_calendar/features/ai/service/ai_api_key_store.dart';
import 'package:ai_calendar/features/ai/service/ai_service.dart';
import 'package:ai_calendar/features/schedule/model/schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _FakeAiService extends AiService {
  _FakeAiService()
      : super(client: http.Client(), keyStore: AiApiKeyStore());

  @override
  Future<Schedule> parse(String naturalLanguage, {DateTime? now}) async {
    return Schedule(
      title: '项目评审会',
      description: '评审 v1.2',
      start: DateTime(2026, 8, 6, 15),
      end: DateTime(2026, 8, 6, 17),
      reminderMinutes: 30,
    );
  }
}

class _DelayedAiService extends AiService {
  _DelayedAiService() : super(client: http.Client(), keyStore: AiApiKeyStore());

  final completer = Completer<Schedule>();

  @override
  Future<Schedule> parse(String naturalLanguage, {DateTime? now}) {
    return completer.future;
  }
}

void main() {
  testWidgets('AI 解析成功后标题与描述输入框同步刷新', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiServiceProvider.overrideWithValue(_FakeAiService()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    final aiField = find.byType(TextField).first;
    await tester.enterText(aiField, '明天下午三点开项目评审会');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('项目评审会'), findsOneWidget);
    expect(find.text('评审 v1.2'), findsOneWidget);
  });

  testWidgets('AI 解析中显示 loading 并禁用提交', (tester) async {
    final service = _DelayedAiService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiServiceProvider.overrideWithValue(service),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '明天下午开会');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(find.text('正在调用 AI 解析日程，可能需要数十秒，请稍候…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsWidgets);
    expect(find.text('AI 解析中...'), findsOneWidget);
    final submitButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('AI 解析中...'),
        matching: find.bySubtype<FilledButton>(),
      ),
    );
    expect(submitButton.onPressed, isNull);

    service.completer.complete(
      Schedule(
        title: '项目评审会',
        start: DateTime(2026, 8, 6, 15),
        end: DateTime(2026, 8, 6, 17),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('项目评审会'), findsOneWidget);
    expect(find.text('AI 解析中...'), findsNothing);
  });
}
