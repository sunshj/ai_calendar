import 'package:flutter/material.dart';

class DescriptionField extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;

  const DescriptionField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      maxLines: 3,
      maxLength: 1000,
      decoration: const InputDecoration(
        labelText: '描述',
        hintText: '议程、参会人、地点等（可选）',
        prefixIcon: Icon(Icons.subject),
        alignLabelWithHint: true,
      ),
    );
  }
}
