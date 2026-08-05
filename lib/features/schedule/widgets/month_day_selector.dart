import 'package:flutter/material.dart';

class MonthDaySelector extends StatelessWidget {
  final List<int> selected;
  final ValueChanged<int> onChanged;

  const MonthDaySelector({
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
          '月份日期',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(31, (i) => i + 1).map((day) {
            final isSelected = selected.contains(day);
            final isSpecialDay = day == 1 || day == 15 || day == 31;
            return GestureDetector(
              onTap: () => onChanged(day),
              child: Container(
                width: 40,
                height: 40,
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
                  '$day',
                  style: TextStyle(
                    fontWeight:
                        isSpecialDay ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurface,
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
