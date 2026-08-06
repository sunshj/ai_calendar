import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum EndCondition { never, until, count }

class EndConditionEditor extends StatefulWidget {
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

  @override
  State<EndConditionEditor> createState() => _EndConditionEditorState();
}

class _EndConditionEditorState extends State<EndConditionEditor> {
  late final TextEditingController _countController;
  int? _lastCount;

  @override
  void initState() {
    super.initState();
    _countController = TextEditingController(
      text: widget.count != null ? '${widget.count}' : '',
    );
  }

  @override
  void didUpdateWidget(covariant EndConditionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count) {
      if (widget.count != null) {
        _lastCount = widget.count;
      }
      final text = widget.count != null ? '${widget.count}' : '';
      if (_countController.text != text) {
        _countController.text = text;
        _countController.selection =
            TextSelection.collapsed(offset: text.length);
      }
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  EndCondition get _current {
    if (widget.until != null) return EndCondition.until;
    if (widget.count != null) return EndCondition.count;
    return EndCondition.never;
  }

  Future<void> _pickDate() async {
    final start = widget.start;
    final initialDate =
        widget.until ?? start.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(start) ? initialDate : start,
      firstDate: start.add(const Duration(days: 1)),
      lastDate: DateTime(start.year + 10, 12, 31),
    );
    if (picked != null) {
      widget.onUntilChanged(
        DateTime(picked.year, picked.month, picked.day, 23, 59, 59),
      );
    }
  }

  void _select(EndCondition cond) {
    switch (cond) {
      case EndCondition.never:
        widget.onUntilChanged(null);
        widget.onCountChanged(null);
      case EndCondition.until:
        widget.onCountChanged(null);
        widget.onUntilChanged(
          widget.until ?? widget.start.add(const Duration(days: 30)),
        );
      case EndCondition.count:
        widget.onUntilChanged(null);
        widget.onCountChanged(widget.count ?? _lastCount ?? 10);
    }
  }

  Widget? _trailing(EndCondition cond, bool selected) {
    if (!selected) return null;
    if (cond == EndCondition.until) {
      return TextButton.icon(
        onPressed: _pickDate,
        icon: const Icon(Icons.event),
        label: Text(
          widget.until != null
              ? DateFormat('yyyy-MM-dd').format(widget.until!)
              : '选择日期',
        ),
      );
    }
    if (cond == EndCondition.count) {
      return SizedBox(
        width: 90,
        child: TextField(
          controller: _countController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          onChanged: (v) {
            final n = int.tryParse(v);
            widget.onCountChanged(n == null || n <= 0 ? null : n);
          },
          decoration: const InputDecoration(
            isDense: true,
            suffixText: '次',
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      );
    }
    return null;
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
          final selected = _current == cond;
          return RadioListTile<EndCondition>(
            value: cond,
            groupValue: _current,
            onChanged: (v) {
              if (v != null) _select(v);
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(cond.displayName),
            secondary: _trailing(cond, selected),
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
