# AI Calendar

基于 Flutter 的 AI 日程助手：用一句自然语言描述日程，AI 自动解析并写入系统日历。

## 功能

- **AI 自然语言解析**：接入 OpenAI Chat Completions 兼容提供商（默认 DeepSeek V4 Flash），把"明天下午三点开项目评审会，持续两小时，每周三重复直到十月底"解析为结构化日程
- 手动表单兜底：标题 / 描述 / 时间 / 重复规则（每日、每周、每月、每年 + 结束条件）/ 提醒
- Android 系统日历写入：MethodChannel + CalendarContract（含 RRULE 重复规则）
- Material 3 UI，flutter_riverpod 状态管理，go_router 路由

## 运行

```bash
flutter pub get
flutter run
```

## 配置 AI 提供商

应用默认使用 DeepSeek（`deepseek-v4-flash`）。点击 AI 输入卡右上角的钥匙图标，
可以切换预设（DeepSeek / OpenAI）或自定义任意 OpenAI Chat Completions 兼容提供商，
填写接口地址、模型和 API Key（保存在本地 SharedPreferences）。
接口地址填基础地址（如 `https://api.deepseek.com`）或完整 `/chat/completions` 地址均可。

也可以启动时注入（不落盘，应用内保存的配置优先）：

```bash
flutter run --dart-define=AI_API_KEY=sk-xxx
flutter run --dart-define=AI_API_KEY=sk-xxx \
  --dart-define=AI_BASE_URL=https://api.openai.com/v1 \
  --dart-define=AI_MODEL=gpt-4o-mini
```

请勿把真实 Key 提交到 Git。

## 测试

```bash
flutter analyze
flutter test
```
