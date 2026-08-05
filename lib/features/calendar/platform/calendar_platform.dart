import '../../schedule/model/schedule.dart';

abstract class CalendarPlatform {
  Future<bool> checkPermissions();
  Future<bool> requestPermissions();
  Future<String> createSchedule(Schedule schedule);
  Future<void> updateSchedule(String eventId, Schedule schedule);
  Future<void> deleteSchedule(String eventId);
  Future<List<Schedule>> querySchedules({DateTime? start, DateTime? end});
}
