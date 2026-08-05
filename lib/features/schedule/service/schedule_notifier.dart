import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calendar/platform/calendar_platform.dart';
import '../../calendar/platform/calendar_method_channel.dart';
import '../model/repeat_rule.dart';
import '../model/schedule.dart';
import '../repository/schedule_repository.dart';
import '../service/schedule_service.dart';

final calendarPlatformProvider = Provider<CalendarPlatform>((ref) {
  return CalendarMethodChannel();
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final platform = ref.watch(calendarPlatformProvider);
  return ScheduleRepositoryImpl(platform);
});

final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  final repo = ref.watch(scheduleRepositoryProvider);
  return ScheduleService(repo);
});

class ScheduleFormState {
  final Schedule schedule;
  final bool isSubmitting;
  final Object? error;
  final String? lastCreatedEventId;

  const ScheduleFormState({
    required this.schedule,
    this.isSubmitting = false,
    this.error,
    this.lastCreatedEventId,
  });

  ScheduleFormState copyWith({
    Schedule? schedule,
    bool? isSubmitting,
    Object? error,
    String? lastCreatedEventId,
    bool clearError = false,
    bool clearEventId = false,
  }) {
    return ScheduleFormState(
      schedule: schedule ?? this.schedule,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      lastCreatedEventId:
          clearEventId ? null : (lastCreatedEventId ?? this.lastCreatedEventId),
    );
  }
}

class ScheduleNotifier extends StateNotifier<ScheduleFormState> {
  final ScheduleService _service;

  ScheduleNotifier(this._service, Schedule initial)
      : super(ScheduleFormState(schedule: initial));

  void updateTitle(String title) {
    state = state.copyWith(
      schedule: state.schedule.copyWith(title: title),
      clearError: true,
    );
  }

  void updateDescription(String? description) {
    state = state.copyWith(
      schedule: state.schedule.copyWith(
        description: description,
        clearDescription: description == null,
      ),
      clearError: true,
    );
  }

  void updateStart(DateTime start) {
    state = state.copyWith(
      schedule: state.schedule.copyWith(start: start),
      clearError: true,
    );
  }

  void updateEnd(DateTime end) {
    state = state.copyWith(
      schedule: state.schedule.copyWith(end: end),
      clearError: true,
    );
  }

  void updateReminderMinutes(int minutes) {
    state = state.copyWith(
      schedule: state.schedule.copyWith(reminderMinutes: minutes),
      clearError: true,
    );
  }

  void updateRepeatRule(RepeatRule? repeatRule) {
    state = state.copyWith(
      schedule: state.schedule.copyWith(
        repeatRule: repeatRule,
        clearRepeatRule: repeatRule == null,
      ),
      clearError: true,
    );
  }

  void reset({Schedule? initial}) {
    state = ScheduleFormState(
      schedule: initial ?? _defaultSchedule(),
    );
  }

  Future<String?> submit() async {
    if (state.isSubmitting) return null;
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearEventId: true,
    );
    try {
      final eventId = await _service.createSchedule(state.schedule);
      state = state.copyWith(
        isSubmitting: false,
        lastCreatedEventId: eventId,
      );
      return eventId;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e,
      );
      return null;
    }
  }

  static Schedule _defaultSchedule() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, now.hour, 0)
        .add(const Duration(hours: 1));
    final end = start.add(const Duration(hours: 1));
    return Schedule(
      title: '',
      start: start,
      end: end,
      reminderMinutes: 15,
    );
  }
}

final scheduleNotifierProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleFormState>((ref) {
  final service = ref.watch(scheduleServiceProvider);
  return ScheduleNotifier(service, ScheduleNotifier._defaultSchedule());
});
