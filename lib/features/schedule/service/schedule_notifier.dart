import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/ai_providers.dart';
import '../../ai/service/ai_service.dart';
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
  final bool isParsing;
  final Object? error;
  final Object? aiError;
  final String? lastCreatedEventId;
  /// 表单被重置的次数，供表单内非 FormField 控件（如 AI 输入框）感知重置。
  final int resetCount;

  const ScheduleFormState({
    required this.schedule,
    this.isSubmitting = false,
    this.isParsing = false,
    this.error,
    this.aiError,
    this.lastCreatedEventId,
    this.resetCount = 0,
  });

  ScheduleFormState copyWith({
    Schedule? schedule,
    bool? isSubmitting,
    bool? isParsing,
    Object? error,
    Object? aiError,
    String? lastCreatedEventId,
    int? resetCount,
    bool clearError = false,
    bool clearAiError = false,
    bool clearEventId = false,
  }) {
    return ScheduleFormState(
      schedule: schedule ?? this.schedule,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isParsing: isParsing ?? this.isParsing,
      error: clearError ? null : (error ?? this.error),
      aiError: clearAiError ? null : (aiError ?? this.aiError),
      lastCreatedEventId:
          clearEventId ? null : (lastCreatedEventId ?? this.lastCreatedEventId),
      resetCount: resetCount ?? this.resetCount,
    );
  }
}

class ScheduleNotifier extends StateNotifier<ScheduleFormState> {
  final ScheduleService _service;
  final AiService _aiService;

  ScheduleNotifier(this._service, this._aiService, Schedule initial)
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

  void updateReminderMinutes(int? minutes) {
    state = state.copyWith(
      schedule: state.schedule.copyWith(
        reminderMinutes: minutes,
        clearReminder: minutes == null,
      ),
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
      resetCount: state.resetCount + 1,
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

  /// 调用 DeepSeek V4 Flash 解析自然语言，成功后填充整个表单。
  Future<bool> fillFromAi(String input) async {
    if (state.isParsing) return false;
    state = state.copyWith(
      isParsing: true,
      clearAiError: true,
      clearEventId: true,
    );
    try {
      final parsed = await _aiService.parse(input);
      state = state.copyWith(
        schedule: parsed,
        isParsing: false,
        clearError: true,
        clearAiError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isParsing: false,
        aiError: e,
      );
      return false;
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
  final aiService = ref.watch(aiServiceProvider);
  return ScheduleNotifier(
    service,
    aiService,
    ScheduleNotifier._defaultSchedule(),
  );
});
