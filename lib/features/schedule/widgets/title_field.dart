import 'package:flutter/material.dart';

class TitleField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const TitleField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<TitleField> createState() => _TitleFieldState();
}

class _TitleFieldState extends State<TitleField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(TitleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // AI 填充等外部值变化时同步输入框；用户正在输入时不打断光标。
    // 延迟到帧后执行，避免在 build 阶段触发 Form 的 setState。
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.text != widget.value) {
          _controller.text = widget.value;
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
