import '../../schedule/model/frequency.dart';
import '../../schedule/model/repeat_rule.dart';
import '../../schedule/model/schedule.dart';
import '../../schedule/model/weekday.dart';

/// LLM 返回内容无法转换为合法 [Schedule] 时抛出。
class AiParseException implements Exception {
  final String message;

  const AiParseException(this.message);

  @override
  String toString() => message;
}

/// 把 LLM 返回的 JSON Map 转换为 [Schedule]。
///
/// LLM 的约定（见 prompt/system_prompt.dart）：
/// - 所有时间为本地绝对时间 ISO8601（无时区后缀）
/// - end 可缺省，用 durationMinutes 推算
/// - repeatRule 为 null 表示不重复
///
/// 传入 [now] 时，重复日程的 start 若落在过去（模型常见错误），会自动推平到
/// 当前时间之后最近的一次未来发生日，避免过去的月份被创建出来。
Schedule scheduleFromLlmJson(Map<String, dynamic> json, {DateTime? now}) {
  final title = (json['title'] as String?)?.trim();
  if (title == null || title.isEmpty) {
    throw const AiParseException('AI 返回结果缺少日程标题（title）');
  }

  final start = _parseDateTime(json['start'], field: 'start');
  if (start == null) {
    throw const AiParseException('AI 返回结果缺少有效的开始时间（start）');
  }

  final durationMinutes =
      (json['durationMinutes'] as num?)?.toInt() ?? _defaultDurationMinutes;
  final end = _parseDateTime(json['end'], field: 'end') ??
      start.add(Duration(minutes: durationMinutes));
  final finalEnd = end.isAfter(start) ? end : start.add(const Duration(hours: 1));

  final reminderMinutes = _parseReminder(json);

  var schedule = Schedule(
    title: title,
    description: (json['description'] as String?)?.trim(),
    start: start,
    end: finalEnd,
    reminderMinutes: reminderMinutes,
    repeatRule: _parseRepeatRule(json['repeatRule'], start),
  );

  if (now != null &&
      schedule.repeatRule?.isRepeating == true &&
      !schedule.start.isAfter(now)) {
    schedule = _shiftToNextOccurrence(schedule, now);
  }
  return schedule;
}

const _defaultDurationMinutes = 60;
const _defaultReminderMinutes = 15;

int? _parseReminder(Map<String, dynamic> json) {
  final raw = json['reminderMinutes'];
  if (raw is num) {
    final value = raw.toInt();
    return value < 0 ? 0 : value;
  }
  // 显式 null = 不提醒；字段缺失时用默认值。
  if (json.containsKey('reminderMinutes')) return null;
  return _defaultReminderMinutes;
}

RepeatRule? _parseRepeatRule(Object? raw, DateTime start) {
  if (raw is! Map<String, dynamic> || raw.isEmpty) return null;

  final frequency = Frequency.fromRruleValue((raw['frequency'] as String?) ?? '');
  if (frequency == Frequency.none) return null;

  final interval = (raw['interval'] as num?)?.toInt() ?? 1;
  final byDay = _parseByDay(raw['byDay'], frequency: frequency, start: start);
  final byMonthDay = _parseByMonthDay(raw['byMonthDay']);

  DateTime? until;
  final untilRaw = raw['until'];
  if (untilRaw is String && untilRaw.trim().isNotEmpty) {
    until = _parseDateTime(untilRaw, field: 'until');
  }
  final count = (raw['count'] as num?)?.toInt();

  return RepeatRule(
    frequency: frequency,
    interval: interval < 1 ? 1 : interval,
    byDay: byDay,
    byMonthDay: byMonthDay,
    until: until,
    count: count,
  );
}

List<Weekday> _parseByDay(Object? raw, {required Frequency frequency, required DateTime start}) {
  final result = <Weekday>[];
  if (raw is List) {
    for (final item in raw) {
      final value = item.toString().trim().toUpperCase();
      final match = Weekday.values.where((d) => d.rruleValue == value);
      if (match.isNotEmpty && !result.contains(match.first)) {
        result.add(match.first);
      }
    }
  }
  // 每周重复但没指定星期时，默认按开始当天
  if (frequency == Frequency.weekly && result.isEmpty) {
    result.add(Weekday.fromDateTime(start));
  }
  return result;
}

List<int> _parseByMonthDay(Object? raw) {
  final result = <int>[];
  if (raw is List) {
    for (final item in raw) {
      final value = (item is num) ? item.toInt() : int.tryParse(item.toString());
      if (value != null && value >= 1 && value <= 31 && !result.contains(value)) {
        result.add(value);
      }
    }
  }
  return result;
}

/// 把重复日程的 start 推进到 [now] 之后最近的一次发生日，保持时长不变。
Schedule _shiftToNextOccurrence(Schedule schedule, DateTime now) {
  final rule = schedule.repeatRule!;
  final duration = schedule.end.difference(schedule.start);

  for (var i = 0; i < 735; i++) {
    final day = DateTime(
      schedule.start.year,
      schedule.start.month,
      schedule.start.day + i,
      schedule.start.hour,
      schedule.start.minute,
    );
    if (!day.isAfter(now)) continue;
    if (!_matchesRule(day, rule, schedule.start)) continue;
    return schedule.copyWith(
      start: day,
      end: day.add(duration),
    );
  }
  return schedule;
}

bool _matchesRule(DateTime day, RepeatRule rule, DateTime originalStart) {
  switch (rule.frequency) {
    case Frequency.daily:
      return true;
    case Frequency.weekly:
      return rule.byDay.isEmpty ||
          rule.byDay.contains(Weekday.fromDateTime(day));
    case Frequency.monthly:
      return rule.byMonthDay.isEmpty || rule.byMonthDay.contains(day.day);
    case Frequency.yearly:
      return day.month == originalStart.month && day.day == originalStart.day;
    case Frequency.none:
      return false;
  }
}

DateTime? _parseDateTime(Object? raw, {required String field}) {
  if (raw is! String || raw.trim().isEmpty) return null;
  var value = raw.trim();
  // 纯日期按当天 23:59:59 处理（用于 until）
  if (field == 'until' && value.length == 10) {
    value = '${value}T23:59:59';
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}
