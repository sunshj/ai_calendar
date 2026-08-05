import '../model/schedule.dart';
import '../repository/schedule_repository.dart';

class ScheduleService {
  final ScheduleRepository _repository;

  ScheduleService(this._repository);

  Future<bool> checkPermissions() => _repository.checkPermissions();

  Future<bool> requestPermissions() => _repository.requestPermissions();

  Future<String> createSchedule(Schedule schedule) async {
    _validate(schedule);
    final hasPermission = await _ensurePermissions();
    if (!hasPermission) {
      throw CalendarPermissionDeniedException();
    }
    return _repository.create(schedule);
  }

  Future<void> updateSchedule(String eventId, Schedule schedule) async {
    _validate(schedule);
    final hasPermission = await _ensurePermissions();
    if (!hasPermission) {
      throw CalendarPermissionDeniedException();
    }
    return _repository.update(eventId, schedule);
  }

  Future<void> deleteSchedule(String eventId) async {
    final hasPermission = await _ensurePermissions();
    if (!hasPermission) {
      throw CalendarPermissionDeniedException();
    }
    return _repository.delete(eventId);
  }

  Future<List<Schedule>> querySchedules({DateTime? start, DateTime? end}) {
    return _repository.query(start: start, end: end);
  }

  void _validate(Schedule schedule) {
    if (schedule.title.trim().isEmpty) {
      throw ScheduleValidationException('标题不能为空');
    }
    if (!schedule.end.isAfter(schedule.start)) {
      throw ScheduleValidationException('结束时间必须晚于开始时间');
    }
    if (schedule.reminderMinutes < 0) {
      throw ScheduleValidationException('提醒时间不能为负数');
    }
    final rrule = schedule.repeatRule;
    if (rrule != null && rrule.isRepeating) {
      if (rrule.interval <= 0) {
        throw ScheduleValidationException('重复间隔必须大于 0');
      }
      if (rrule.count != null && rrule.count! <= 0) {
        throw ScheduleValidationException('重复次数必须大于 0');
      }
      if (rrule.until != null && !rrule.until!.isAfter(schedule.start)) {
        throw ScheduleValidationException('截止日期必须晚于开始时间');
      }
    }
  }

  Future<bool> _ensurePermissions() async {
    if (await _repository.checkPermissions()) return true;
    return _repository.requestPermissions();
  }
}

class ScheduleValidationException implements Exception {
  final String message;
  ScheduleValidationException(this.message);

  @override
  String toString() => 'ScheduleValidationException: $message';
}

class CalendarPermissionDeniedException implements Exception {
  @override
  String toString() => 'CalendarPermissionDeniedException: 日历权限被拒绝';
}
