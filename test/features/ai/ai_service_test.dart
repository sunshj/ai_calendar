import 'dart:convert';

import 'package:ai_calendar/features/ai/model/ai_provider_config.dart';
import 'package:ai_calendar/features/ai/parser/schedule_parser.dart';
import 'package:ai_calendar/features/ai/service/ai_provider_store.dart';
import 'package:ai_calendar/features/ai/service/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AiProviderStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = AiProviderStore();
  });

  AiService serviceWith(MockClient client) {
    return AiService(client: client, store: store);
  }

  Map<String, dynamic> completionResponse(String content) {
    return {
      'id': 'chatcmpl-test',
      'choices': [
        {
          'index': 0,
          'message': {'role': 'assistant', 'content': content},
          'finish_reason': 'stop',
        },
      ],
    };
  }

  http.Response okJson(String content) {
    return http.Response(
      jsonEncode(completionResponse(content)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  test('未配置 API Key 时抛 AiApiKeyMissingException', () async {
    final service = serviceWith(
      MockClient((_) async => http.Response('{}', 200)),
    );

    expect(
      () => service.parse('明天下午开会'),
      throwsA(isA<AiApiKeyMissingException>()),
    );
  });

  test('默认 DeepSeek：请求构造正确且返回 Schedule', () async {
    await store.save(AiProviderConfig.deepSeek(apiKey: 'sk-test-key'));

    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return okJson('''
{
  "title": "项目评审会",
  "start": "2026-08-06T15:00:00",
  "durationMinutes": 120,
  "reminderMinutes": 15,
  "repeatRule": null
}
''');
    });

    final schedule = await serviceWith(client).parse('明天下午三点开会两小时');

    expect(captured.method, 'POST');
    expect(captured.url.toString(), 'https://api.deepseek.com/chat/completions');
    expect(captured.headers['Authorization'], 'Bearer sk-test-key');

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['model'], 'deepseek-v4-flash');
    expect(body['response_format'], {'type': 'json_object'});
    expect(body['temperature'], 0.1);
    final messages = body['messages'] as List<dynamic>;
    expect(messages.first['role'], 'system');
    expect(messages.first['content'], contains('JSON'));
    expect(messages.last['role'], 'user');

    expect(schedule.title, '项目评审会');
    expect(schedule.start, DateTime(2026, 8, 6, 15));
    expect(schedule.end, DateTime(2026, 8, 6, 17));
  });

  test('支持自定义 OpenAI 兼容提供商', () async {
    await store.save(
      const AiProviderConfig(
        name: '自定义',
        baseUrl: 'https://my-proxy.example.com/v1',
        model: 'gpt-4o-mini',
        apiKey: 'sk-custom-key',
      ),
    );

    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return okJson('{"title": "晨会", "start": "2026-08-06T09:00:00"}');
    });

    final schedule = await serviceWith(client).parse('明早九点晨会');

    expect(
      captured.url.toString(),
      'https://my-proxy.example.com/v1/chat/completions',
    );
    expect(captured.headers['Authorization'], 'Bearer sk-custom-key');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['model'], 'gpt-4o-mini');
    expect(schedule.title, '晨会');
  });

  test('接口地址未带 /chat/completions 时自动补齐', () async {
    await store.save(
      const AiProviderConfig(
        name: '自定义',
        baseUrl: 'https://my.example.com/',
        model: 'deepseek-chat',
        apiKey: 'sk-x',
      ),
    );

    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return okJson('{"title": "晨会", "start": "2026-08-06T09:00:00"}');
    });

    await serviceWith(client).parse('明早九点晨会');
    expect(captured.url.toString(), 'https://my.example.com/chat/completions');
  });

  test('旧版单独保存的 DeepSeek Key 可迁移读取', () async {
    SharedPreferences.setMockInitialValues({
      'deepseek_api_key': 'sk-legacy-key',
    });

    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return okJson('{"title": "晨会", "start": "2026-08-06T09:00:00"}');
    });

    await serviceWith(client).parse('明早九点晨会');

    expect(
      captured.url.toString(),
      'https://api.deepseek.com/chat/completions',
    );
    expect(captured.headers['Authorization'], 'Bearer sk-legacy-key');
  });

  test('带 Markdown 代码围栏也能解析', () async {
    await store.save(AiProviderConfig.deepSeek(apiKey: 'sk-test-key'));

    final client = MockClient(
      (_) async => okJson('''```json
{"title": "晨会", "start": "2026-08-06T09:00:00"}
```'''),
    );

    final schedule = await serviceWith(client).parse('明早九点晨会');
    expect(schedule.title, '晨会');
    expect(schedule.start, DateTime(2026, 8, 6, 9));
  });

  test('内容带前后说明文字也能提取 JSON', () async {
    await store.save(AiProviderConfig.deepSeek(apiKey: 'sk-test-key'));

    final client = MockClient(
      (_) async => okJson('好的，解析结果如下：\n'
          '{"title": "晨会", "start": "2026-08-06T09:00:00", '
          '"durationMinutes": 30}\n请查收。'),
    );

    final schedule = await serviceWith(client).parse('明早九点晨会');
    expect(schedule.title, '晨会');
    expect(schedule.start, DateTime(2026, 8, 6, 9));
  });

  test('首次输出非法 JSON 时自动重试一次', () async {
    await store.save(AiProviderConfig.deepSeek(apiKey: 'sk-test-key'));

    var calls = 0;
    late http.Request secondRequest;
    final client = MockClient((request) async {
      calls++;
      if (calls == 1) {
        return okJson('抱歉，我无法理解这个请求');
      }
      secondRequest = request;
      return okJson('{"title": "晨会", "start": "2026-08-06T09:00:00"}');
    });

    final schedule = await serviceWith(client).parse('明早九点晨会');

    expect(calls, 2);
    expect(schedule.title, '晨会');

    final body = jsonDecode(secondRequest.body) as Map<String, dynamic>;
    final messages = body['messages'] as List<dynamic>;
    expect(messages.length, 4);
    expect(messages.last['content'], contains('无法解析'));
  });

  test('非 2xx 响应抛 AiApiException 并透出错误信息', () async {
    await store.save(AiProviderConfig.deepSeek(apiKey: 'sk-test-key'));

    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'error': {'message': 'Authentication Fails'},
        }),
        401,
        headers: {'content-type': 'application/json'},
      ),
    );

    expect(
      () => serviceWith(client).parse('明天开会'),
      throwsA(
        isA<AiApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', contains('Authentication')),
      ),
    );
  });

  test('重试后仍非法 JSON 抛 AiParseException', () async {
    await store.save(AiProviderConfig.deepSeek(apiKey: 'sk-test-key'));

    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return okJson('not a json at all');
    });

    await expectLater(
      serviceWith(client).parse('明天开会'),
      throwsA(isA<AiParseException>()),
    );
    expect(calls, 2);
  });
}
