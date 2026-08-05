# AI Calendar

基于 Flutter 的 AI 日程助手：用一句自然语言描述日程，AI 自动解析并写入系统日历。

## 功能

- **AI 自然语言解析**：接入 DeepSeek V4 Flash（`deepseek-v4-flash`），把"明天下午三点开项目评审会，持续两小时，每周三重复直到十月底"解析为结构化日程
- 手动表单兜底：标题 / 描述 / 时间 / 重复规则（每日、每周、每月、每年 + 结束条件）/ 提醒
- Android 系统日历写入：MethodChannel + CalendarContract（含 RRULE 重复规则）
- Material 3 UI，flutter_riverpod 状态管理，go_router 路由

## 运行

```bash
flutter pub get
flutter run
```

## 配置 DeepSeek API Key

两种方式，应用内保存的 Key 优先：

1. 运行 App 后，点击 AI 输入卡右上角的钥匙图标，填入 Key（保存在本地 SharedPreferences）
2. 启动时注入（不落盘）：

```bash
flutter run --dart-define=AI_API_KEY=sk-xxx
```

Key 保存在 `api.deepseek.com` 调用，模型为 `deepseek-v4-flash`，使用 OpenAI ChatCompletions 兼容接口与 JSON Output 模式。请勿把真实 Key 提交到 Git。

## 测试

```bash
flutter analyze
flutter test
```
