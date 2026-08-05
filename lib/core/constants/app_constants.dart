class AppConstants {
  static const String appName = 'AI Calendar';

  static const String scheduleRoute = '/';
  static const String historyRoute = '/history';
  static const String settingsRoute = '/settings';
  static const String aiRoute = '/ai';
  static const String debugRoute = '/debug';

  static const String calendarChannel = 'com.example.ai_calendar/calendar';

  static const int defaultReminderMinutes = 15;
}

class MethodChannelConstants {
  static const String createSchedule = 'createSchedule';
  static const String updateSchedule = 'updateSchedule';
  static const String deleteSchedule = 'deleteSchedule';
  static const String querySchedules = 'querySchedules';
  static const String requestPermissions = 'requestPermissions';
  static const String checkPermissions = 'checkPermissions';
}
