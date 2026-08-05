import 'repeat_rule.dart';

class Schedule {
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final int reminderMinutes;
  final RepeatRule? repeatRule;

  const Schedule({
    required this.title,
    this.description,
    required this.start,
    required this.end,
    this.reminderMinutes = 15,
    this.repeatRule,
  });

  Schedule copyWith({
    String? title,
    String? description,
    DateTime? start,
    DateTime? end,
    int? reminderMinutes,
    RepeatRule? repeatRule,
    bool clearDescription = false,
    bool clearRepeatRule = false,
  }) {
    return Schedule(
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      start: start ?? this.start,
      end: end ?? this.end,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      repeatRule: clearRepeatRule ? null : (repeatRule ?? this.repeatRule),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'start': start.toUtc().toIso8601String(),
      'end': end.toUtc().toIso8601String(),
      'reminderMinutes': reminderMinutes,
      'repeatRule': repeatRule?.toJson(),
    };
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    final repeatRuleJson = json['repeatRule'] as Map<String, dynamic>?;
    return Schedule(
      title: json['title'] as String,
      description: json['description'] as String?,
      start: DateTime.parse(json['start'] as String).toLocal(),
      end: DateTime.parse(json['end'] as String).toLocal(),
      reminderMinutes: (json['reminderMinutes'] as num?)?.toInt() ?? 15,
      repeatRule:
          repeatRuleJson == null ? null : RepeatRule.fromJson(repeatRuleJson),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Schedule &&
        other.title == title &&
        other.description == description &&
        other.start == start &&
        other.end == end &&
        other.reminderMinutes == reminderMinutes &&
        other.repeatRule == repeatRule;
  }

  @override
  int get hashCode => Object.hash(
        title,
        description,
        start,
        end,
        reminderMinutes,
        repeatRule,
      );

  @override
  String toString() {
    return 'Schedule(title: $title, start: $start, end: $end, '
        'reminder: ${reminderMinutes}min, repeat: $repeatRule)';
  }
}
