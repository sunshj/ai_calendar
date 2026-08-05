enum Weekday {
  monday(1, '一', 'MO'),
  tuesday(2, '二', 'TU'),
  wednesday(3, '三', 'WE'),
  thursday(4, '四', 'TH'),
  friday(5, '五', 'FR'),
  saturday(6, '六', 'SA'),
  sunday(7, '日', 'SU');

  final int isoValue;
  final String shortName;
  final String rruleValue;

  const Weekday(this.isoValue, this.shortName, this.rruleValue);

  static Weekday fromIso(int isoDay) {
    return Weekday.values.firstWhere(
      (d) => d.isoValue == isoDay,
      orElse: () => Weekday.monday,
    );
  }

  static Weekday fromDateTime(DateTime date) {
    return fromIso(date.weekday);
  }

  static Weekday fromRrule(String value) {
    return Weekday.values.firstWhere(
      (d) => d.rruleValue == value.toUpperCase(),
      orElse: () => Weekday.monday,
    );
  }

  static List<Weekday> get weekdays => [
        Weekday.monday,
        Weekday.tuesday,
        Weekday.wednesday,
        Weekday.thursday,
        Weekday.friday,
      ];

  static List<Weekday> get weekend => [
        Weekday.saturday,
        Weekday.sunday,
      ];
}
