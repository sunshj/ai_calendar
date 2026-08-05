import 'package:flutter/material.dart';

class ReminderSelector extends StatelessWidget {
  final int valueMinutes;
  final ValueChanged<int> onChanged;

  static const List<int> options = [0, 5, 10, 15, 30, 60, 120, 1440];

  const ReminderSelector({
    super.key,
    required this.valueMinutes,
    required this.onChanged,
  });

  String _label(int minutes) {
    return switch (minutes) {
      0 => '不提醒',
      < 60 => '$minutes 分钟前',
      60 => '1 小时前',
      < 1440 => '${minutes ~/ 60} 小时前',
      1440 => '1 天前',
      _ => '${minutes ~/ 1440} 天前',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '提醒',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((minutes) {
            final selected = valueMinutes == minutes;
            return ChoiceChip(
              label: Text(_label(minutes)),
              selected: selected,
              avatar: Icon(
                selected ? Icons.alarm_on : Icons.alarm,
                size: 18,
              ),
              onSelected: (_) => onChanged(minutes),
            );
          }).toList(),
        ),
      ],
    );
  }
}
