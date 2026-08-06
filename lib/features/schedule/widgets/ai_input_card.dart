import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../ai/ai_providers.dart';
import '../../ai/model/ai_provider_config.dart';
import '../../ai/parser/schedule_parser.dart';
import '../../ai/service/ai_service.dart';
import '../service/schedule_notifier.dart';

class AiInputCard extends ConsumerStatefulWidget {
  const AiInputCard({super.key});

  @override
  ConsumerState<AiInputCard> createState() => _AiInputCardState();
}

class _AiInputCardState extends ConsumerState<AiInputCard> {
  final _controller = TextEditingController();
  int? _lastResetCount;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _parse() async {
    if (_controller.text.trim().isEmpty) return;
    final notifier = ref.read(scheduleNotifierProvider.notifier);
    final ok = await notifier.fillFromAi(_controller.text);
    if (!mounted) return;
    if (ok) {
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已解析并填入表单，请核对后创建日程'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showProviderDialog() async {
    final store = ref.read(aiProviderStoreProvider);
    final stored = await store.load() ?? AiProviderConfig.deepSeek();
    if (!mounted) return;

    const injectedKey = String.fromEnvironment('AI_API_KEY');
    const injectedBaseUrl = String.fromEnvironment('AI_BASE_URL');
    const injectedModel = String.fromEnvironment('AI_MODEL');

    final result = await showDialog<_ProviderDialogResult>(
      context: context,
      builder: (_) => _ProviderSettingsDialog(
        initial: stored,
        injectedKey: injectedKey,
        injectedBaseUrl: injectedBaseUrl,
        injectedModel: injectedModel,
      ),
    );

    if (!mounted || result == null) return;
    if (result.clearApiKey) {
      await store.clearApiKey();
    } else {
      await store.save(result.config!);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.clearApiKey ? '已清除 API Key' : 'AI 提供商配置已保存',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatError(Object error) {
    if (error is AiApiKeyMissingException) return error.toString();
    if (error is AiApiException) return error.toString();
    if (error is AiParseException) return error.toString();
    if (error is TimeoutException) return '请求超时，请稍后重试';
    if (error is http.ClientException) return '网络请求失败，请检查网络连接';
    return '解析失败：$error';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formState = ref.watch(scheduleNotifierProvider);
    if (_lastResetCount != formState.resetCount) {
      _lastResetCount = formState.resetCount;
      if (_controller.text.isNotEmpty) {
        // 延迟到帧后，避免在 build 阶段修改控制器触发 setState 报错。
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _controller.text.isNotEmpty) {
            _controller.clear();
          }
        });
      }
    }
    final isParsing = formState.isParsing;
    final aiError = formState.aiError;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'AI 助手',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'AI 提供商设置',
                  icon: const Icon(Icons.key),
                  onPressed: isParsing ? null : _showProviderDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 2,
              enabled: !isParsing,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _parse(),
              decoration: InputDecoration(
                hintText: '例：明天下午三点开项目评审会，持续两小时，每周三重复直到十月底',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
                prefixIcon: const Icon(Icons.auto_awesome_outlined),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isParsing)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    else
                      IconButton(
                        tooltip: '解析',
                        icon: const Icon(Icons.send),
                        onPressed: _parse,
                      ),
                  ],
                ),
              ),
            ),
            if (isParsing) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '正在调用 AI 解析日程，可能需要数十秒，请稍候…',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 3),
            ],
            if (aiError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatError(aiError),
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '输入一句话，AI 自动解析并填充下方表单，核对后点击创建',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderSettingsDialog extends StatefulWidget {
  final AiProviderConfig initial;
  final String injectedKey;
  final String injectedBaseUrl;
  final String injectedModel;

  const _ProviderSettingsDialog({
    required this.initial,
    required this.injectedKey,
    required this.injectedBaseUrl,
    required this.injectedModel,
  });

  @override
  State<_ProviderSettingsDialog> createState() => _ProviderSettingsDialogState();
}

class _ProviderSettingsDialogState extends State<_ProviderSettingsDialog> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;
  late String _selectedPreset;
  var _obscure = true;
  var _errorText = '';

  @override
  void initState() {
    super.initState();
    final config = widget.initial;
    _apiKeyController = TextEditingController(
      text: config.apiKey ?? widget.injectedKey,
    );
    _baseUrlController = TextEditingController(
      text: widget.injectedBaseUrl.isNotEmpty
          ? widget.injectedBaseUrl
          : config.baseUrl,
    );
    _modelController = TextEditingController(
      text: widget.injectedModel.isNotEmpty ? widget.injectedModel : config.model,
    );
    _selectedPreset = _matchPreset(config.baseUrl);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  String _matchPreset(String baseUrl) {
    for (final preset in aiProviderPresets) {
      if (preset.baseUrl.isNotEmpty && preset.baseUrl == baseUrl) {
        return preset.name;
      }
    }
    return '自定义';
  }

  void _applyPreset(AiProviderPreset preset) {
    setState(() {
      _selectedPreset = preset.name;
      if (preset.baseUrl.isNotEmpty) {
        _baseUrlController.text = preset.baseUrl;
      }
      if (preset.model.isNotEmpty) {
        _modelController.text = preset.model;
      }
      _errorText = '';
    });
  }

  void _save() {
    final baseUrl = _baseUrlController.text.trim();
    final model = _modelController.text.trim();
    if (baseUrl.isEmpty || model.isEmpty) {
      setState(() => _errorText = '接口地址和模型不能为空');
      return;
    }
    final key = _apiKeyController.text.trim();
    Navigator.pop(
      context,
      _ProviderDialogResult.save(
        AiProviderConfig(
          name: _selectedPreset,
          baseUrl: baseUrl,
          model: model,
          apiKey: key.isEmpty ? null : key,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI 提供商设置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: aiProviderPresets.map((preset) {
                return ChoiceChip(
                  label: Text(preset.name),
                  selected: _selectedPreset == preset.name,
                  onSelected: (_) => _applyPreset(preset),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _baseUrlController,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: '接口地址',
                hintText: 'https://api.openai.com/v1/chat/completions',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modelController,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: '模型',
                hintText: 'deepseek-chat / gpt-4o-mini',
                prefixIcon: Icon(Icons.smart_toy_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-...',
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscure = !_obscure);
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_errorText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _errorText,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '任意 OpenAI Chat Completions 兼容接口均可使用。'
              '接口地址填基础地址或完整 /chat/completions 地址都可以。'
              '也可以启动时注入（不落盘）：\n'
              'flutter run --dart-define=AI_API_KEY=sk-xxx '
              '[--dart-define=AI_BASE_URL=https://... '
              '--dart-define=AI_MODEL=xxx]',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const _ProviderDialogResult.clear(),
          ),
          child: const Text('清除 Key'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _ProviderDialogResult {
  final AiProviderConfig? config;
  final bool clearApiKey;

  const _ProviderDialogResult.save(this.config) : clearApiKey = false;
  const _ProviderDialogResult.clear()
      : config = null,
        clearApiKey = true;
}
