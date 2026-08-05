import 'package:flutter/material.dart';

import '../model/weekday.dart';

class WeekdaySelector extends StatelessWidget {
  final List<Weekday> selected;
  final ValueChanged<Weekday> onChanged;

  const WeekdaySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '星期',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: Weekday.values.map((day) {
            final isSelected = selected.contains(day);
            final isWeekend = day == Weekday.saturday || day == Weekday.sunday;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: () => onChanged(day),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      day.shortName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : isWeekend
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
