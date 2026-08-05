import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/extension/datetime_extension.dart';

class DateTimePickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateTimePickerField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
  });

  Future<void> _pick(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
    );
    if (pickedDate == null) return;
    if (!context.mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDayExtension.fromDateTime(value),
    );
    if (pickedTime == null) return;
    onChanged(pickedDate.combine(pickedTime));
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(value);
    final timeStr = DateFormat('HH:mm').format(value);
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: Icon(Icons.edit_calendar, color: colorScheme.primary),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                dateStr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                timeStr,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
