import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../schedule/model/schedule.dart';
import '../parser/schedule_parser.dart';
import '../prompt/system_prompt.dart';
import 'ai_api_key_store.dart';

const _deepSeekEndpoint = 'https://api.deepseek.com/chat/completions';
const _deepSeekModel = 'deepseek-v4-flash';
const _requestTimeout = Duration(seconds: 45);
const _maxTokens = 2048;
const _temperature = 0.1;
const _maxAttempts = 2;

/// 未配置 API Key 时抛出。
class AiApiKeyMissingException implements Exception {
  const AiApiKeyMissingException();

  @override
  String toString() => '未配置 DeepSeek API Key，请在 AI 输入卡的设置中填入';
}

/// DeepSeek API 返回非 2xx 或响应结构异常时抛出。
class AiApiException implements Exception {
  final int statusCode;
  final String message;

  const AiApiException(this.statusCode, this.message);

  @override
  String toString() => 'DeepSeek API 错误($statusCode)：$message';
}

/// 调用 DeepSeek V4 Flash 把自然语言解析为 [Schedule]。
class AiService {
  final http.Client _client;
  final AiApiKeyStore _keyStore;

  AiService({
    required http.Client client,
    required AiApiKeyStore keyStore,
  })  : _client = client,
        _keyStore = keyStore;

  /// 解析一句自然语言日程描述，返回 [Schedule]。
  ///
  /// [now] 仅供测试注入当前时间；生产环境默认取 [DateTime.now]。
  Future<Schedule> parse(String naturalLanguage, {DateTime? now}) async {
    final text = naturalLanguage.trim();
    if (text.isEmpty) {
      throw const AiParseException('请输入日程描述');
    }

    final apiKey = await _resolveApiKey();
    if (apiKey.isEmpty) {
      throw const AiApiKeyMissingException();
    }

    final currentTime = now ?? DateTime.now();
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': AiSystemPrompt.build(now: currentTime)},
      {'role': 'user', 'content': text},
    ];

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final content = await _chat(messages, apiKey);
      try {
        final decoded = _decodeJsonObject(content);
        if (decoded == null) {
          throw const AiParseException('AI 返回的内容不是合法 JSON');
        }
        return scheduleFromLlmJson(decoded);
      } on AiParseException catch (e) {
        if (attempt == _maxAttempts - 1) rethrow;
        // 追加一轮纠错：告诉模型上次输出无法解析，重新只输出 JSON。
        messages.addAll([
          {'role': 'assistant', 'content': content},
          {
            'role': 'user',
            'content': '你刚才的输出无法解析（${e.message}）。'
                '请重新输出：只输出一个 JSON 对象，不要 Markdown 代码块，'
                '不要任何解释或多余文字，并且必须包含 title 和 start 字段。',
          },
        ]);
      }
    }
    throw const AiParseException('AI 返回的内容不是合法 JSON');
  }

  Future<String> _resolveApiKey() async {
    const injected = String.fromEnvironment('AI_API_KEY');
    final stored = await _keyStore.load();
    if (stored != null && stored.isNotEmpty) return stored;
    return injected;
  }

  /// 从 chat completion 响应中取出 assistant 的 content，去掉可能的代码块围栏。
  static String? _extractContent(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) return null;
      final message = (choices.first as Map<String, dynamic>)['message'];
      if (message is! Map<String, dynamic>) return null;
      final content = message['content']?.toString();
      return _stripCodeFence(content ?? '');
    } catch (_) {
      return null;
    }
  }

  static String _stripCodeFence(String content) {
    var text = content.trim();
    if (text.startsWith('```')) {
      final firstNewline = text.indexOf('\n');
      if (firstNewline != -1) {
        text = text.substring(firstNewline + 1);
      }
      final fenceIndex = text.lastIndexOf('```');
      if (fenceIndex != -1) {
        text = text.substring(0, fenceIndex);
      }
      text = text.trim();
    }
    return text;
  }

  /// 尝试把模型输出解析为 JSON 对象。
  ///
  /// 先直接解析；失败时去掉首尾多余文字，提取第一个平衡的 `{...}` 块再解析。
  static Map<String, dynamic>? _decodeJsonObject(String raw) {
    final text = _stripCodeFence(raw.trim());
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // 走下面的容错提取
    }

    final start = text.indexOf('{');
    if (start == -1) return null;

    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < text.length; i++) {
      final ch = text[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == r'\') {
          escaped = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }
      if (ch == '"') {
        inString = true;
      } else if (ch == '{') {
        depth++;
      } else if (ch == '}') {
        depth--;
        if (depth == 0) {
          try {
            final decoded = jsonDecode(text.substring(start, i + 1));
            if (decoded is Map<String, dynamic>) return decoded;
          } on FormatException {
            return null;
          }
        }
      }
    }
    return null;
  }

  Future<String> _chat(List<Map<String, String>> messages, String apiKey) async {
    final requestBody = jsonEncode({
      'model': _deepSeekModel,
      'messages': messages,
      'response_format': {'type': 'json_object'},
      'temperature': _temperature,
      'max_tokens': _maxTokens,
    });

    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_deepSeekEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: requestBody,
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const AiApiException(0, '请求超时，请稍后重试');
    } on http.ClientException catch (e) {
      throw AiApiException(0, '网络请求失败：${e.message}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiApiException(
        response.statusCode,
        _extractErrorMessage(response.body),
      );
    }
    return _extractContent(response.body) ?? '';
  }

  static String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final error = decoded['error'];
      if (error is Map<String, dynamic> && error['message'] != null) {
        return error['message'].toString();
      }
      final message = decoded['message'];
      if (message != null) return message.toString();
    } catch (_) {
      // 忽略解析失败，使用默认文案
    }
    return '服务暂时不可用，请稍后重试';
  }
}
