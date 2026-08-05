import 'package:ai_calendar/features/schedule/model/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Schedule.reminderMinutes JSON 回环', () {
    test('数字正常往返', () {
      final schedule = Schedule.fromJson({
        'title': '测试',
        'start': '2026-08-06T02:00:00.000Z',
        'end': '2026-08-06T03:00:00.000Z',
        'reminderMinutes': 30,
      });
      expect(schedule.reminderMinutes, 30);
    });

    test('0 表示开始时提醒', () {
      final schedule = Schedule.fromJson({
        'title': '测试',
        'start': '2026-08-06T02:00:00.000Z',
        'end': '2026-08-06T03:00:00.000Z',
        'reminderMinutes': 0,
      });
      expect(schedule.reminderMinutes, 0);
    });

    test('null 表示不提醒', () {
      final schedule = Schedule.fromJson({
        'title': '测试',
        'start': '2026-08-06T02:00:00.000Z',
        'end': '2026-08-06T03:00:00.000Z',
        'reminderMinutes': null,
      });
      expect(schedule.reminderMinutes, isNull);
      expect(schedule.toJson()['reminderMinutes'], isNull);
    });

    test('字段缺失时默认 15 分钟', () {
      final schedule = Schedule.fromJson({
        'title': '测试',
        'start': '2026-08-06T02:00:00.000Z',
        'end': '2026-08-06T03:00:00.000Z',
      });
      expect(schedule.reminderMinutes, 15);
    });
  });
}
