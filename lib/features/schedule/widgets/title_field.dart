import 'package:flutter/material.dart';

class TitleField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const TitleField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      textInputAction: TextInputAction.next,
      maxLength: 200,
      decoration: const InputDecoration(
        labelText: '标题',
        hintText: '例如：项目评审会',
        prefixIcon: Icon(Icons.title),
        counterText: '',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return '请输入标题';
        return null;
      },
    );
  }
}
