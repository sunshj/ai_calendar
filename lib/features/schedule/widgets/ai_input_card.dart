import 'package:flutter/material.dart';

class AiInputCard extends StatelessWidget {
  const AiInputCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 2,
              enabled: false,
              decoration: InputDecoration(
                hintText: '例：明天下午三点开项目评审会，持续两小时，每周三重复直到十月底',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
                prefixIcon: const Icon(Icons.mic_none),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('AI 自然语言解析功能将在后续版本开放'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '当前阶段请手动填写下方表单',
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
