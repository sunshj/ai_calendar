import 'package:shared_preferences/shared_preferences.dart';

/// DeepSeek API Key 的本地持久化。
///
/// 优先级：应用内保存的 Key > `--dart-define=AI_API_KEY` 注入的 Key。
class AiApiKeyStore {
  static const _prefsKey = 'deepseek_api_key';

  Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefsKey);
    return (value == null || value.trim().isEmpty) ? null : value.trim();
  }

  Future<void> save(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, key.trim());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
