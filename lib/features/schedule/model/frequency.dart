enum Frequency {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  String get displayName {
    return switch (this) {
      Frequency.none => '不重复',
      Frequency.daily => '每天',
      Frequency.weekly => '每周',
      Frequency.monthly => '每月',
      Frequency.yearly => '每年',
    };
  }

  String get rruleValue {
    return switch (this) {
      Frequency.none => throw StateError('None frequency has no RRULE value'),
      Frequency.daily => 'DAILY',
      Frequency.weekly => 'WEEKLY',
      Frequency.monthly => 'MONTHLY',
      Frequency.yearly => 'YEARLY',
    };
  }

  static Frequency fromRruleValue(String value) {
    return switch (value.toUpperCase()) {
      'DAILY' => Frequency.daily,
      'WEEKLY' => Frequency.weekly,
      'MONTHLY' => Frequency.monthly,
      'YEARLY' => Frequency.yearly,
      _ => Frequency.none,
    };
  }
}
