import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../ai/ai_providers.dart';
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

  Future<void> _showApiKeyDialog() async {
    final store = ref.read(aiApiKeyStoreProvider);
    const injected = String.fromEnvironment('AI_API_KEY');
    final current = await store.load() ?? injected;
    if (!mounted) return;

    final controller = TextEditingController(text: current);
    var obscure = true;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('DeepSeek API Key'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    obscureText: obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'sk-...',
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setDialogState(() => obscure = !obscure);
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '保存后优先使用应用内 Key；也可以在启动时注入：\n'
                    'flutter run --dart-define=AI_API_KEY=sk-xxx',
                    style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                          color: Theme.of(dialogContext)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, ''),
                  child: const Text('清除'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, controller.text.trim()),
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    if (result.isEmpty) {
      await store.clear();
    } else {
      await store.save(result);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isEmpty ? '已清除 API Key' : 'API Key 已保存'),
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
                  tooltip: 'API Key 设置',
                  icon: const Icon(Icons.key),
                  onPressed: isParsing ? null : _showApiKeyDialog,
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
