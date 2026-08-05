import 'package:ai_calendar/features/ai/parser/schedule_parser.dart';
import 'package:ai_calendar/features/schedule/model/frequency.dart';
import 'package:ai_calendar/features/schedule/model/weekday.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('scheduleFromLlmJson', () {
    test('解析完整 JSON', () {
      final schedule = scheduleFromLlmJson({
        'title': '项目评审会',
        'description': '评审 v1.2',
        'start': '2026-08-06T15:00:00',
        'end': '2026-08-06T17:00:00',
        'durationMinutes': 120,
        'reminderMinutes': 30,
        'repeatRule': {
          'frequency': 'WEEKLY',
          'interval': 1,
          'byDay': ['WE'],
          'byMonthDay': [],
          'until': '2026-10-31T23:59:59',
          'count': null,
        },
      });

      expect(schedule.title, '项目评审会');
      expect(schedule.description, '评审 v1.2');
      expect(schedule.start, DateTime(2026, 8, 6, 15));
      expect(schedule.end, DateTime(2026, 8, 6, 17));
      expect(schedule.reminderMinutes, 30);
      final rule = schedule.repeatRule;
      expect(rule, isNotNull);
      expect(rule!.frequency, Frequency.weekly);
      expect(rule.interval, 1);
      expect(rule.byDay, [Weekday.wednesday]);
      expect(rule.until, DateTime(2026, 10, 31, 23, 59, 59));
      expect(rule.count, isNull);
    });

    test('缺少 end 时用 durationMinutes 推算', () {
      final schedule = scheduleFromLlmJson({
        'title': '晨会',
        'start': '2026-08-06T09:00:00',
        'durationMinutes': 45,
      });

      expect(schedule.end, DateTime(2026, 8, 6, 9, 45));
    });

    test('end 早于 start 时回退为开始后一小时', () {
      final schedule = scheduleFromLlmJson({
        'title': '异常数据',
        'start': '2026-08-06T10:00:00',
        'end': '2026-08-06T09:00:00',
      });

      expect(schedule.end, DateTime(2026, 8, 6, 11));
    });

    test('每周重复未指定 byDay 时默认开始当天', () {
      final schedule = scheduleFromLlmJson({
        'title': '周会',
        'start': '2026-08-05T10:00:00', // 周三
        'repeatRule': {
          'frequency': 'WEEKLY',
          'interval': 1,
        },
      });

      expect(schedule.repeatRule!.byDay, [Weekday.wednesday]);
    });

    test('until 纯日期补 23:59:59', () {
      final schedule = scheduleFromLlmJson({
        'title': '健身',
        'start': '2026-08-06T07:00:00',
        'repeatRule': {
          'frequency': 'DAILY',
          'until': '2026-08-31',
        },
      });

      expect(
        schedule.repeatRule!.until,
        DateTime(2026, 8, 31, 23, 59, 59),
      );
    });

    test('非法 byDay 忽略，越界 byMonthDay 丢弃', () {
      final schedule = scheduleFromLlmJson({
        'title': '月例会',
        'start': '2026-08-10T14:00:00',
        'repeatRule': {
          'frequency': 'MONTHLY',
          'byDay': ['XX', 'MO', 'mo'],
          'byMonthDay': [1, 32, 0, 20],
        },
      });

      expect(schedule.repeatRule!.byDay, [Weekday.monday]);
      expect(schedule.repeatRule!.byMonthDay, [1, 20]);
    });

    test('负提醒时间归零', () {
      final schedule = scheduleFromLlmJson({
        'title': '测试',
        'start': '2026-08-06T10:00:00',
        'reminderMinutes': -5,
      });

      expect(schedule.reminderMinutes, 0);
    });

    test('reminderMinutes 为 0 表示开始时提醒', () {
      final schedule = scheduleFromLlmJson({
        'title': '测试',
        'start': '2026-08-06T10:00:00',
        'reminderMinutes': 0,
      });

      expect(schedule.reminderMinutes, 0);
    });

    test('reminderMinutes 为 null 表示不提醒', () {
      final schedule = scheduleFromLlmJson({
        'title': '测试',
        'start': '2026-08-06T10:00:00',
        'reminderMinutes': null,
      });

      expect(schedule.reminderMinutes, isNull);
    });

    test('缺少 reminderMinutes 时默认 15 分钟', () {
      final schedule = scheduleFromLlmJson({
        'title': '测试',
        'start': '2026-08-06T10:00:00',
      });

      expect(schedule.reminderMinutes, 15);
    });

    test('repeatRule 为 null 或空时不重复', () {
      final schedule = scheduleFromLlmJson({
        'title': '单次',
        'start': '2026-08-06T10:00:00',
        'repeatRule': null,
      });
      expect(schedule.repeatRule, isNull);

      final empty = scheduleFromLlmJson({
        'title': '单次',
        'start': '2026-08-06T10:00:00',
        'repeatRule': {'frequency': ''},
      });
      expect(empty.repeatRule, isNull);
    });

    test('缺少标题抛 AiParseException', () {
      expect(
        () => scheduleFromLlmJson({'start': '2026-08-06T10:00:00'}),
        throwsA(isA<AiParseException>()),
      );
    });

    test('缺少开始时间抛 AiParseException', () {
      expect(
        () => scheduleFromLlmJson({'title': '无时间'}),
        throwsA(isA<AiParseException>()),
      );
    });

    group('start 落在过去时的未来发生日推平', () {
      final now = DateTime(2026, 8, 5, 12);

      test('每月 8 号从 1 月开始会推平到 8 月 8 日', () {
        final schedule = scheduleFromLlmJson(
          {
            'title': '零食店会员日',
            'start': '2026-01-08T20:00:00',
            'end': '2026-01-08T21:00:00',
            'reminderMinutes': 0,
            'repeatRule': {
              'frequency': 'MONTHLY',
              'byMonthDay': [8],
              'until': '2026-12-31T23:59:59',
            },
          },
          now: now,
        );

        expect(schedule.start, DateTime(2026, 8, 8, 20));
        expect(schedule.end, DateTime(2026, 8, 8, 21));
        expect(schedule.repeatRule!.until, DateTime(2026, 12, 31, 23, 59, 59));
      });

      test('每周一起始的系列推平到下一个周一', () {
        final schedule = scheduleFromLlmJson(
          {
            'title': '周会',
            'start': '2026-08-03T09:00:00', // 周一，已过去
            'repeatRule': {
              'frequency': 'WEEKLY',
              'byDay': ['MO'],
            },
          },
          now: now,
        );

        expect(schedule.start, DateTime(2026, 8, 10, 9));
      });

      test('每日系列推平到明天', () {
        final schedule = scheduleFromLlmJson(
          {
            'title': '每日打卡',
            'start': '2026-08-04T08:00:00',
            'repeatRule': {
              'frequency': 'DAILY',
            },
          },
          now: now,
        );

        expect(schedule.start, DateTime(2026, 8, 6, 8));
      });

      test('不重复的过去日程不推平', () {
        final schedule = scheduleFromLlmJson(
          {
            'title': '补录',
            'start': '2026-01-08T10:00:00',
          },
          now: now,
        );

        expect(schedule.start, DateTime(2026, 1, 8, 10));
      });

      test('start 已在未来时不改动', () {
        final schedule = scheduleFromLlmJson(
          {
            'title': '未来日程',
            'start': '2026-08-08T20:00:00',
            'repeatRule': {
              'frequency': 'MONTHLY',
              'byMonthDay': [8],
            },
          },
          now: now,
        );

        expect(schedule.start, DateTime(2026, 8, 8, 20));
      });
    });
  });
}
