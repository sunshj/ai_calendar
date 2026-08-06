/// OpenAI Chat Completions 兼容的默认提供商。
const deepSeekEndpoint = 'https://api.deepseek.com/chat/completions';
const deepSeekModel = 'deepseek-v4-flash';
const openAiEndpoint = 'https://api.openai.com/v1/chat/completions';
const openAiModel = 'gpt-4o-mini';

/// 一个 OpenAI Chat Completions 兼容提供商的配置。
class AiProviderConfig {
  final String name;
  final String baseUrl;
  final String model;
  final String? apiKey;

  const AiProviderConfig({
    required this.name,
    required this.baseUrl,
    required this.model,
    this.apiKey,
  });

  factory AiProviderConfig.deepSeek({String? apiKey}) {
    return AiProviderConfig(
      name: 'DeepSeek',
      baseUrl: deepSeekEndpoint,
      model: deepSeekModel,
      apiKey: apiKey,
    );
  }

  factory AiProviderConfig.openAi({String? apiKey}) {
    return AiProviderConfig(
      name: 'OpenAI',
      baseUrl: openAiEndpoint,
      model: openAiModel,
      apiKey: apiKey,
    );
  }

  AiProviderConfig copyWith({
    String? name,
    String? baseUrl,
    String? model,
    String? apiKey,
    bool clearApiKey = false,
  }) {
    return AiProviderConfig(
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      apiKey: clearApiKey ? null : (apiKey ?? this.apiKey),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'baseUrl': baseUrl,
      'model': model,
      'apiKey': apiKey,
    };
  }

  factory AiProviderConfig.fromJson(Map<String, dynamic> json) {
    return AiProviderConfig(
      name: (json['name'] as String?) ?? '自定义',
      baseUrl: (json['baseUrl'] as String?) ?? '',
      model: (json['model'] as String?) ?? '',
      apiKey: json['apiKey'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiProviderConfig &&
        other.name == name &&
        other.baseUrl == baseUrl &&
        other.model == model &&
        other.apiKey == apiKey;
  }

  @override
  int get hashCode => Object.hash(name, baseUrl, model, apiKey);

  @override
  String toString() {
    return 'AiProviderConfig(name: $name, baseUrl: $baseUrl, '
        'model: $model, apiKey: ${apiKey == null ? null : '***'})';
  }
}

/// 设置弹窗里的可选预设。
class AiProviderPreset {
  final String name;
  final String baseUrl;
  final String model;

  const AiProviderPreset({
    required this.name,
    required this.baseUrl,
    required this.model,
  });
}

const List<AiProviderPreset> aiProviderPresets = [
  AiProviderPreset(
    name: 'DeepSeek',
    baseUrl: deepSeekEndpoint,
    model: deepSeekModel,
  ),
  AiProviderPreset(
    name: 'OpenAI',
    baseUrl: openAiEndpoint,
    model: openAiModel,
  ),
  AiProviderPreset(name: '自定义', baseUrl: '', model: ''),
];
