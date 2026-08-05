import 'frequency.dart';
import 'weekday.dart';

class RepeatRule {
  final Frequency frequency;
  final int interval;
  final List<Weekday> byDay;
  final List<int> byMonthDay;
  final DateTime? until;
  final int? count;

  const RepeatRule({
    this.frequency = Frequency.none,
    this.interval = 1,
    this.byDay = const [],
    this.byMonthDay = const [],
    this.until,
    this.count,
  });

  bool get isRepeating => frequency != Frequency.none;

  RepeatRule copyWith({
    Frequency? frequency,
    int? interval,
    List<Weekday>? byDay,
    List<int>? byMonthDay,
    DateTime? until,
    int? count,
    bool clearUntil = false,
    bool clearCount = false,
  }) {
    return RepeatRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      byDay: byDay ?? this.byDay,
      byMonthDay: byMonthDay ?? this.byMonthDay,
      until: clearUntil ? null : (until ?? this.until),
      count: clearCount ? null : (count ?? this.count),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency == Frequency.none ? null : frequency.rruleValue,
      'interval': interval,
      'byDay': byDay.map((d) => d.rruleValue).toList(),
      'byMonthDay': List<int>.from(byMonthDay),
      'until': until?.toUtc().toIso8601String(),
      'count': count,
    };
  }

  factory RepeatRule.fromJson(Map<String, dynamic> json) {
    final freqStr = json['frequency'] as String?;
    final frequency =
        freqStr == null ? Frequency.none : Frequency.fromRruleValue(freqStr);

    final byDayList = (json['byDay'] as List<dynamic>?)
            ?.map((e) => Weekday.fromRrule(e.toString()))
            .toList() ??
        <Weekday>[];

    final byMonthDayList = (json['byMonthDay'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ??
        <int>[];

    final untilStr = json['until'] as String?;

    return RepeatRule(
      frequency: frequency,
      interval: (json['interval'] as num?)?.toInt() ?? 1,
      byDay: byDayList,
      byMonthDay: byMonthDayList,
      until: untilStr == null ? null : DateTime.parse(untilStr).toLocal(),
      count: (json['count'] as num?)?.toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RepeatRule &&
        other.frequency == frequency &&
        other.interval == interval &&
        _listEquals(other.byDay, byDay) &&
        _listEquals(other.byMonthDay, byMonthDay) &&
        other.until == until &&
        other.count == count;
  }

  @override
  int get hashCode => Object.hash(
        frequency,
        interval,
        Object.hashAll(byDay),
        Object.hashAll(byMonthDay),
        until,
        count,
      );

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'RepeatRule(freq: ${frequency.name}, interval: $interval, '
        'byDay: ${byDay.map((d) => d.shortName).join(',')}, '
        'byMonthDay: $byMonthDay, until: $until, count: $count)';
  }
}
