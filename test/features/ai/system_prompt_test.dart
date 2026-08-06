import 'package:ai_calendar/features/ai/prompt/system_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('提示词中的示例时间必须是严格 ISO 格式（T 分隔、无毫秒、无空格）', () {
    final prompt = AiSystemPrompt.build(now: DateTime(2026, 8, 6, 19, 40));

    // 示例 1 的固定时间必须原样出现
    expect(prompt, contains('"start": "2026-08-07T15:00:00"'));
    expect(prompt, contains('"end": "2026-08-07T17:00:00"'));
    expect(prompt, contains('当前时间：2026-08-06T19:40（周四，本地时间）'));

    // 不允许出现毫秒或空格分隔的旧格式（Dart DateTime.toString 的产物）
    expect(prompt, isNot(contains('.000')));
    expect(prompt, isNot(contains('T00:00:00.000')));
    expect(prompt, isNot(contains(' 15:00:00.000')));

    final isoPattern = RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}');
    final spacePattern = RegExp(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}');

    // 示例里应该有不少严格 ISO 时间
    expect(isoPattern.allMatches(prompt).length, greaterThanOrEqualTo(6));
    // 输出格式不能有空格分隔的日期时间
    expect(spacePattern.hasMatch(prompt), isFalse);
  });

  test('提示词明确 end 必填且等于 start + durationMinutes', () {
    final prompt = AiSystemPrompt.build(now: DateTime(2026, 8, 6, 19, 40));
    expect(prompt, contains('end 必须出现'));
    expect(prompt, contains('end 必须等于 start 加上 durationMinutes'));
  });
}
