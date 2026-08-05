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
    final requestBody = jsonEncode({
      'model': _deepSeekModel,
      'messages': [
        {'role': 'system', 'content': AiSystemPrompt.build(now: currentTime)},
        {'role': 'user', 'content': text},
      ],
      'response_format': {'type': 'json_object'},
      'temperature': 0.2,
      'max_tokens': 1024,
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

    final content = _extractContent(response.body);
    if (content == null) {
      throw const AiApiException(0, 'AI 返回内容无法解析');
    }

    final decoded = _decodeJson(content);
    if (decoded is! Map<String, dynamic>) {
      throw const AiParseException('AI 返回的 JSON 结构不是对象');
    }
    return scheduleFromLlmJson(decoded);
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

  static Object? _decodeJson(String content) {
    try {
      return jsonDecode(content);
    } on FormatException {
      throw const AiParseException('AI 返回的内容不是合法 JSON');
    }
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
