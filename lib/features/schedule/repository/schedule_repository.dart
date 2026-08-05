import '../../calendar/platform/calendar_platform.dart';
import '../model/schedule.dart';

abstract class ScheduleRepository {
  Future<bool> checkPermissions();
  Future<bool> requestPermissions();
  Future<String> create(Schedule schedule);
  Future<void> update(String eventId, Schedule schedule);
  Future<void> delete(String eventId);
  Future<List<Schedule>> query({DateTime? start, DateTime? end});
}

class ScheduleRepositoryImpl implements ScheduleRepository {
  final CalendarPlatform _calendarPlatform;

  ScheduleRepositoryImpl(this._calendarPlatform);

  @override
  Future<bool> checkPermissions() => _calendarPlatform.checkPermissions();

  @override
  Future<bool> requestPermissions() => _calendarPlatform.requestPermissions();

  @override
  Future<String> create(Schedule schedule) => _calendarPlatform.createSchedule(schedule);

  @override
  Future<void> update(String eventId, Schedule schedule) =>
      _calendarPlatform.updateSchedule(eventId, schedule);

  @override
  Future<void> delete(String eventId) => _calendarPlatform.deleteSchedule(eventId);

  @override
  Future<List<Schedule>> query({DateTime? start, DateTime? end}) =>
      _calendarPlatform.querySchedules(start: start, end: end);
}
