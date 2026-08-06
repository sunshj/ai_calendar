import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/ai_provider_config.dart';

/// AI 提供商配置的本地持久化。
///
/// 优先级：应用内保存的配置 > `--dart-define` 注入的配置。
class AiProviderStore {
  static const _prefsKey = 'ai_provider_config';
  static const _legacyKeyPrefsKey = 'deepseek_api_key';

  /// 读取已保存的配置；没有配置或配置损坏时，
  /// 回退到旧版本单独保存的 DeepSeek API Key（迁移兼容）。
  Future<AiProviderConfig?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return AiProviderConfig.fromJson(decoded);
        }
      } catch (_) {
        // 配置损坏时忽略，回退到旧版 Key
      }
    }

    final legacyKey = prefs.getString(_legacyKeyPrefsKey);
    if (legacyKey != null && legacyKey.trim().isNotEmpty) {
      return AiProviderConfig.deepSeek(apiKey: legacyKey.trim());
    }
    return null;
  }

  Future<void> save(AiProviderConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(config.toJson()));
  }

  Future<void> clearApiKey() async {
    final config = await load();
    if (config == null) return;
    await save(config.copyWith(clearApiKey: true));
  }
}
