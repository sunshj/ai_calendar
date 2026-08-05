import 'package:flutter/material.dart';

class DescriptionField extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChanged;

  const DescriptionField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<DescriptionField> createState() => _DescriptionFieldState();
}

class _DescriptionFieldState extends State<DescriptionField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(DescriptionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 延迟到帧后执行，避免在 build 阶段触发 Form 的 setState。
    if (oldWidget.value != widget.value &&
        _controller.text != (widget.value ?? '')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.text != (widget.value ?? '')) {
          _controller.text = widget.value ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      onChanged: widget.onChanged,
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
