import 'package:flutter/material.dart';

import '../../../shared/extension/datetime_extension.dart';
import '../model/frequency.dart';
import '../model/repeat_rule.dart';
import '../model/weekday.dart';
import 'end_condition_editor.dart';
import 'month_day_selector.dart';
import 'weekday_selector.dart';

class RepeatRuleEditor extends StatelessWidget {
  final RepeatRule? value;
  final ValueChanged<RepeatRule?> onChanged;
  final DateTime eventStart;

  const RepeatRuleEditor({
    super.key,
    required this.value,
    required this.onChanged,
    required this.eventStart,
  });

  RepeatRule get _rule => value ?? const RepeatRule();
  bool get _isRepeating => _rule.isRepeating;

  void _setFrequency(Frequency freq) {
    if (freq == Frequency.none) {
      onChanged(null);
      return;
    }
    RepeatRule newRule = _rule.copyWith(frequency: freq);
    if (freq != Frequency.weekly) {
      newRule = newRule.copyWith(byDay: <Weekday>[]);
    } else if (newRule.byDay.isEmpty) {
      newRule = newRule.copyWith(byDay: [Weekday.fromDateTime(eventStart)]);
    }
    if (freq != Frequency.monthly) {
      newRule = newRule.copyWith(byMonthDay: <int>[]);
    } else if (newRule.byMonthDay.isEmpty) {
      newRule = newRule.copyWith(byMonthDay: [eventStart.day]);
    }
    onChanged(newRule);
  }

  void _setInterval(int interval) {
    onChanged(_rule.copyWith(interval: interval.max(1)));
  }

  void _toggleByDay(Weekday day) {
    final list = List<Weekday>.from(_rule.byDay);
    if (list.contains(day)) {
      list.remove(day);
    } else {
      list.add(day);
      list.sort((a, b) => a.isoValue.compareTo(b.isoValue));
    }
    onChanged(_rule.copyWith(byDay: list));
  }

  void _toggleByMonthDay(int day) {
    final list = List<int>.from(_rule.byMonthDay);
    if (list.contains(day)) {
      list.remove(day);
    } else {
      list.add(day);
      list.sort();
    }
    onChanged(_rule.copyWith(byMonthDay: list));
  }

  void _setUntil(DateTime? until) {
    onChanged(_rule.copyWith(
      until: until,
      clearUntil: until == null,
    ));
  }

  void _setCount(int? count) {
    onChanged(_rule.copyWith(
      count: count,
      clearCount: count == null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FrequencySelector(
          value: _isRepeating ? _rule.frequency : Frequency.none,
          onChanged: _setFrequency,
        ),
        if (_isRepeating) ...[
          const SizedBox(height: 16),
          _IntervalEditor(
            frequency: _rule.frequency,
            interval: _rule.interval,
            onChanged: _setInterval,
          ),
          if (_rule.frequency == Frequency.weekly) ...[
            const SizedBox(height: 16),
            WeekdaySelector(
              selected: _rule.byDay,
              onChanged: _toggleByDay,
            ),
          ],
          if (_rule.frequency == Frequency.monthly) ...[
            const SizedBox(height: 16),
            MonthDaySelector(
              selected: _rule.byMonthDay,
              onChanged: _toggleByMonthDay,
            ),
          ],
          const SizedBox(height: 16),
          EndConditionEditor(
            count: _rule.count,
            until: _rule.until,
            onCountChanged: _setCount,
            onUntilChanged: _setUntil,
            start: eventStart,
          ),
        ],
      ],
    );
  }
}

class _FrequencySelector extends StatelessWidget {
  final Frequency value;
  final ValueChanged<Frequency> onChanged;

  const _FrequencySelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '重复',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Frequency.values.map((freq) {
            final selected = value == freq;
            return ChoiceChip(
              label: Text(freq.displayName),
              selected: selected,
              onSelected: (_) => onChanged(freq),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _IntervalEditor extends StatelessWidget {
  final Frequency frequency;
  final int interval;
  final ValueChanged<int> onChanged;

  const _IntervalEditor({
    required this.frequency,
    required this.interval,
    required this.onChanged,
  });

  String get _unitName {
    return switch (frequency) {
      Frequency.daily => '天',
      Frequency.weekly => '周',
      Frequency.monthly => '月',
      Frequency.yearly => '年',
      Frequency.none => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('每'),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            controller: TextEditingController(text: '$interval'),
            onChanged: (v) {
              final n = int.tryParse(v);
              if (n != null && n > 0) onChanged(n);
            },
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(_unitName),
      ],
    );
  }
}
