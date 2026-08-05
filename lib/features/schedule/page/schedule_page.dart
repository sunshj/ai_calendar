import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../service/schedule_notifier.dart';
import '../service/schedule_service.dart';
import '../widgets/ai_input_card.dart';
import '../widgets/datetime_picker_field.dart';
import '../widgets/description_field.dart';
import '../widgets/reminder_selector.dart';
import '../widgets/repeat_rule_editor.dart';
import '../widgets/title_field.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final notifier = ref.read(scheduleNotifierProvider.notifier);
    final eventId = await notifier.submit();

    if (!mounted) return;

    final state = ref.read(scheduleNotifierProvider);
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_formatError(state.error!)),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (eventId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('日程创建成功！Event ID: $eventId')),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatError(Object err) {
    if (err is ScheduleValidationException) return err.message;
    if (err is CalendarPermissionDeniedException) return '没有日历权限，请在设置中授权';
    return '创建失败：${err.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(scheduleNotifierProvider);
    final notifier = ref.read(scheduleNotifierProvider.notifier);
    final schedule = formState.schedule;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '重置表单',
            icon: const Icon(Icons.restart_alt),
            onPressed: (formState.isSubmitting || formState.isParsing)
                ? null
                : () {
                    notifier.reset();
                    _formKey.currentState?.reset();
                  },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AiInputCard(),
              const SizedBox(height: 20),
              _SectionCard(
                title: '基本信息',
                icon: Icons.event_note,
                children: [
                  TitleField(
                    value: schedule.title,
                    onChanged: notifier.updateTitle,
                  ),
                  const SizedBox(height: 16),
                  DescriptionField(
                    value: schedule.description,
                    onChanged: notifier.updateDescription,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: '时间',
                icon: Icons.schedule,
                children: [
                  DateTimePickerField(
                    label: '开始时间',
                    icon: Icons.play_circle_outline,
                    value: schedule.start,
                    onChanged: (d) {
                      notifier.updateStart(d);
                      if (!d.isBefore(schedule.end)) {
                        notifier.updateEnd(d.add(const Duration(hours: 1)));
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DateTimePickerField(
                    label: '结束时间',
                    icon: Icons.stop_circle_outlined,
                    value: schedule.end,
                    firstDate: schedule.start,
                    onChanged: notifier.updateEnd,
                  ),
                  const SizedBox(height: 8),
                  _DurationHint(start: schedule.start, end: schedule.end),
                ],
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: '重复设置',
                icon: Icons.repeat,
                children: [
                  RepeatRuleEditor(
                    value: schedule.repeatRule,
                    onChanged: notifier.updateRepeatRule,
                    eventStart: schedule.start,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: '提醒',
                icon: Icons.notifications_active,
                children: [
                  ReminderSelector(
                    valueMinutes: schedule.reminderMinutes,
                    onChanged: notifier.updateReminderMinutes,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (formState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatError(formState.error!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              if (formState.lastCreatedEventId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '最近创建的 Event ID: ${formState.lastCreatedEventId}',
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _SubmitBar(
        isSubmitting: formState.isSubmitting,
        isParsing: formState.isParsing,
        onSubmit: _onSubmit,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DurationHint extends StatelessWidget {
  final DateTime start;
  final DateTime end;

  const _DurationHint({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    final diff = end.difference(start);
    if (diff.isNegative || diff.inMinutes == 0) {
      return Text(
        '⚠ 结束时间必须晚于开始时间',
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final label = StringBuffer();
    if (hours > 0) {
      label.write('$hours 小时');
      if (minutes > 0) label.write(' ');
    }
    if (minutes > 0) label.write('$minutes 分钟');
    return Row(
      children: [
        const Icon(Icons.timer_outlined, size: 18),
        const SizedBox(width: 6),
        Text(
          '时长：$label',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final bool isSubmitting;
  final bool isParsing;
  final VoidCallback onSubmit;

  const _SubmitBar({
    required this.isSubmitting,
    required this.isParsing,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final busy = isSubmitting || isParsing;
    final media = MediaQuery.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, media.padding.bottom + 8),
        child: FilledButton.icon(
          onPressed: busy ? null : onSubmit,
          icon: isParsing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Icon(Icons.edit_calendar),
          label: Text(
            isParsing ? 'AI 解析中...' : (isSubmitting ? '创建中...' : '创建日程'),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
String _formatDate(DateTime d) => DateFormat('yyyy-MM-dd HH:mm').format(d);
