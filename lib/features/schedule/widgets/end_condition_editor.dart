import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum EndCondition { never, until, count }

class EndConditionEditor extends StatelessWidget {
  final DateTime? until;
  final int? count;
  final DateTime start;
  final ValueChanged<DateTime?> onUntilChanged;
  final ValueChanged<int?> onCountChanged;

  const EndConditionEditor({
    super.key,
    required this.until,
    required this.count,
    required this.start,
    required this.onUntilChanged,
    required this.onCountChanged,
  });

  EndCondition get _current {
    if (until != null) return EndCondition.until;
    if (count != null) return EndCondition.count;
    return EndCondition.never;
  }

  Future<void> _pickDate(BuildContext context) async {
    final initialDate = until ?? start.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(start) ? initialDate : start,
      firstDate: start.add(const Duration(days: 1)),
      lastDate: DateTime(start.year + 10, 12, 31),
    );
    if (picked != null) {
      onUntilChanged(DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '结束条件',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...EndCondition.values.map((cond) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Radio<EndCondition>(
                  value: cond,
                  groupValue: _current,
                  onChanged: (v) {
                    if (v == EndCondition.never) {
                      onUntilChanged(null);
                      onCountChanged(null);
                    } else if (v == EndCondition.until) {
                      onCountChanged(null);
                      onUntilChanged(until ?? start.add(const Duration(days: 30)));
                    } else if (v == EndCondition.count) {
                      onUntilChanged(null);
                      onCountChanged(count ?? 10);
                    }
                  },
                ),
                Expanded(child: Text(cond.displayName)),
                if (_current == cond && cond == EndCondition.until)
                  TextButton.icon(
                    onPressed: () => _pickDate(context),
                    icon: const Icon(Icons.event),
                    label: Text(until != null
                        ? DateFormat('yyyy-MM-dd').format(until!)
                        : '选择日期'),
                  ),
                if (_current == cond && cond == EndCondition.count)
                  SizedBox(
                    width: 90,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      controller: TextEditingController(
                        text: count != null ? '$count' : '',
                      ),
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        onCountChanged(n == null || n <= 0 ? null : n);
                      },
                      decoration: const InputDecoration(
                        isDense: true,
                        suffixText: '次',
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

extension EndConditionX on EndCondition {
  String get displayName {
    return switch (this) {
      EndCondition.never => '永不结束',
      EndCondition.until => '截止日期',
      EndCondition.count => '重复次数',
    };
  }
}
