import 'package:ai_calendar/features/schedule/model/repeat_rule.dart';
import 'package:ai_calendar/features/schedule/widgets/repeat_rule_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RuleHolder {
  RepeatRule? value;
}

void main() {
  Future<_RuleHolder> pumpEditor(WidgetTester tester) async {
    final holder = _RuleHolder();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => RepeatRuleEditor(
              value: holder.value,
              onChanged: (v) => setState(() => holder.value = v),
              eventStart: DateTime(2026, 8, 6, 9),
            ),
          ),
        ),
      ),
    );
    return holder;
  }

  testWidgets('选中重复后三个结束条件选项都可以通过点击文字选中', (tester) async {
    final holder = await pumpEditor(tester);

    // 先选择“每周”，让结束条件区域出现
    await tester.tap(find.text('每周'));
    await tester.pump();

    expect(find.text('结束条件'), findsOneWidget);

    // 点击“重复次数”文字（而不是小圆点）应该能选中
    await tester.tap(find.text('重复次数'));
    await tester.pump();
    expect(holder.value?.count, 10);
    expect(holder.value?.until, isNull);

    // 再点“截止日期”文字，应互斥清除 count
    await tester.tap(find.text('截止日期'));
    await tester.pump();
    expect(holder.value?.until, isNotNull);
    expect(holder.value?.count, isNull);

    // 最后点“永不结束”文字，应清空两者
    await tester.tap(find.text('永不结束'));
    await tester.pump();
    expect(holder.value?.until, isNull);
    expect(holder.value?.count, isNull);
  });

  testWidgets('重复次数输入框可编辑，且切换条件时互斥清理', (tester) async {
    final holder = await pumpEditor(tester);

    await tester.tap(find.text('每周'));
    await tester.pump();
    await tester.tap(find.text('重复次数'));
    await tester.pump();

    // 编辑重复次数
    await tester.enterText(find.byType(TextField).last, '5');
    await tester.pump();
    expect(holder.value?.count, 5);
    expect(holder.value?.until, isNull);

    // 切到“截止日期”后 count 必须被清空
    await tester.tap(find.text('截止日期'));
    await tester.pump();
    expect(holder.value?.count, isNull);
    expect(holder.value?.until, isNotNull);

    // 再切回“重复次数”，until 必须被清空
    await tester.tap(find.text('重复次数'));
    await tester.pump();
    expect(holder.value?.until, isNull);
    expect(holder.value?.count, 5);
  });
}
