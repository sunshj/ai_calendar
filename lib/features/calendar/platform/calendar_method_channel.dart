import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../schedule/model/schedule.dart';
import 'calendar_platform.dart';

class CalendarMethodChannel implements CalendarPlatform {
  final MethodChannel _channel =
      const MethodChannel(AppConstants.calendarChannel);

  @override
  Future<bool> checkPermissions() async {
    try {
      final result = await _channel
          .invokeMethod<bool>(MethodChannelConstants.checkPermissions);
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      final result = await _channel
          .invokeMethod<bool>(MethodChannelConstants.requestPermissions);
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> createSchedule(Schedule schedule) async {
    final result = await _channel.invokeMethod<String>(
      MethodChannelConstants.createSchedule,
      schedule.toJson(),
    );
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'Failed to create schedule, no event ID returned',
      );
    }
    return result;
  }

  @override
  Future<void> updateSchedule(String eventId, Schedule schedule) async {
    await _channel.invokeMethod<void>(
      MethodChannelConstants.updateSchedule,
      {
        'eventId': eventId,
        'schedule': schedule.toJson(),
      },
    );
  }

  @override
  Future<void> deleteSchedule(String eventId) async {
    await _channel.invokeMethod<void>(
      MethodChannelConstants.deleteSchedule,
      {'eventId': eventId},
    );
  }

  @override
  Future<List<Schedule>> querySchedules({
    DateTime? start,
    DateTime? end,
  }) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      MethodChannelConstants.querySchedules,
      {
        'start': start?.toUtc().toIso8601String(),
        'end': end?.toUtc().toIso8601String(),
      },
    );
    return (result ?? const [])
        .map((e) => Schedule.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
