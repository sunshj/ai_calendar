import 'package:flutter/material.dart';

extension IntExtension on int {
  int max(int other) => this > other ? this : other;
  int min(int other) => this < other ? this : other;
}

extension DateTimeExtension on DateTime {
  DateTime startOfDay() => DateTime(year, month, day);

  DateTime endOfDay() => DateTime(year, month, day, 23, 59, 59, 999);

  DateTime combine(TimeOfDay time) {
    return DateTime(year, month, day, time.hour, time.minute);
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

extension TimeOfDayExtension on TimeOfDay {
  static TimeOfDay fromDateTime(DateTime dt) {
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }
}
