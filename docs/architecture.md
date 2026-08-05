# AI Calendar - 架构设计文档

> Version: 1.0 (MVP)
> Date: 2026-08-05
> Status: Production Ready

---

## 1. 项目定位

**AI Calendar 不是一个日历 App，而是一个 AI Assistant。**

核心价值：

- 用户通过自然语言一句话描述 → AI 自动解析并创建日程
- MVP 阶段手动填写表单，未来接入 AI 后 UI / 业务逻辑 / 平台层 **零改动**

---

## 2. 技术栈

| 层              | 技术                                 | 版本                   |
| --------------- | ------------------------------------ | ---------------------- |
| Flutter SDK     | Stable                               | ^3.7.0                 |
| UI 规范         | Material 3                           | (ColorScheme.fromSeed) |
| 状态管理        | flutter_riverpod                     | ^2.6.1                 |
| 路由            | go_router                            | ^14.8.1                |
| 权限            | permission_handler                   | ^11.3.1                |
| 日期            | intl                                 | ^0.20.2                |
| Android 语言    | Kotlin                               | (JVM 11)               |
| Flutter↔Android | MethodChannel                        | (Flutter Embedding v2) |
| Android 日历    | CalendarContract (Calendar Provider) | (系统 API，无三方插件) |

---

## 3. 架构原则

### 3.1 Feature First（按功能切分）

```
features/
  schedule/    ← 日程表单、创建、查看、历史...
  calendar/    ← 平台日历交互 (MethodChannel, CalendarContract)
  ai/          ← 自然语言 → Schedule 解析（未来）
  settings/    ← 设置（未来）
```

每个 Feature 内部分层：

```
<feature>/
  model/       ← 不可变数据模型 (immutable + copyWith + toJson/fromJson)
  service/     ← 业务规则、校验、状态管理 (Riverpod Notifier)
  repository/  ← 数据源抽象（接口 + 默认实现）
  page/        ← 页面级 Widget
  widgets/     ← 页面子组件（单一职责，<300 行）
```

**不允许的操作：**

- UI 直接调用 MethodChannel
- 业务逻辑塞进 Widget build()
- Feature A 直接引用 Feature B 的私有实现类（通过抽象接口）

### 3.2 SOLID 原则落地

| 原则             | 实现                                                           |
| ---------------- | -------------------------------------------------------------- |
| **S**RP 单一职责 | 每个 Widget < 300 行；`CalendarProvider` 只碰 CalendarContract |
| **O**CP 开闭原则 | `CalendarPlatform` 接口；加 iOS 实现时 Flutter 代码不动        |
| **L**SP 里氏替换 | `MockCalendarPlatform` 可无缝替换 MethodChannel 做测试         |
| **I**SP 接口隔离 | `ScheduleRepository` 接口窄而专；不塞 UI 无关方法              |
| **D**IP 依赖倒置 | 依赖 `CalendarPlatform` (抽象)，不依赖 MethodChannel (细节)    |

### 3.3 数据流：单向依赖

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter UI Layer                        │
│  Page → Widgets → ConsumerWidget / ConsumerStatefulWidget       │
└───────────────────────────┬─────────────────────────────────────┘
                            │ reads / writes
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│              Riverpod State (ScheduleFormState)                 │
│  ScheduleNotifier (StateNotifier)                               │
│    - updateTitle / updateStart / submit / reset                 │
└───────────────────────────┬─────────────────────────────────────┘
                            │ calls
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                   ScheduleService (业务规则)                    │
│  validate() / _ensurePermissions() / createSchedule()          │
│  throws: ScheduleValidationException, PermissionException       │
└───────────────────────────┬─────────────────────────────────────┘
                            │ calls
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│              ScheduleRepository (数据源抽象)                    │
│  Interface: checkPermissions, create, update, delete, query     │
│  Impl: ScheduleRepositoryImpl → delegates to CalendarPlatform    │
└───────────────────────────┬─────────────────────────────────────┘
                            │ depends on (DIP)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│              CalendarPlatform (Abstraction)                     │
│   ↙ MethodChannel         ↙ Mock (test)           ↙ iOS (future)│
│  CalendarMethodChannel   FakeCalendarPlatform    (todo)          │
└───────────────────────────┬─────────────────────────────────────┘
                            │ invokeMethod(JSON)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│              Android: CalendarPlugin (MethodChannel)            │
│  parse JSON → ScheduleDto                                        │
│    → RRuleBuilder.build(repeatRuleMap) → RRULE String            │
│    → CalendarProvider.insertEvent(...) → CalendarContract        │
│  result.success(eventId)                                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. 目录结构

```
ai_calendar/
├── docs/
│   └── architecture.md                 # 本文件
├── lib/
│   ├── main.dart                       # ProviderScope + runApp
│   ├── app.dart                        # MyApp: ConsumerWidget + MaterialApp.router
│   │
│   ├── core/                           # 横切关注点（无 Feature 归属）
│   │   ├── router/app_router.dart      # go_router 配置 + routerProvider
│   │   ├── constants/app_constants.dart# 路由名、Channel 名、默认值
│   │   ├── theme/app_theme.dart        # Material 3 (light/dark, seed: 6750A4)
│   │   └── utils/                      # 未来：logger、错误处理工具
│   │
│   ├── features/
│   │   ├── schedule/                   # ★ MVP 核心功能
│   │   │   ├── model/
│   │   │   │   ├── schedule.dart       # Schedule: 全局唯一业务模型
│   │   │   │   ├── repeat_rule.dart    # RepeatRule + copyWith + toJson
│   │   │   │   ├── frequency.dart      # none/daily/weekly/monthly/yearly
│   │   │   │   └── weekday.dart        # MO..SU + ISO 1-7 + 中文名
│   │   │   ├── service/
│   │   │   │   ├── schedule_service.dart       # 校验 + 权限编排
│   │   │   │   └── schedule_notifier.dart      # StateNotifier + 4 个 Provider
│   │   │   ├── repository/
│   │   │   │   └── schedule_repository.dart    # 接口 + Impl
│   │   │   ├── page/
│   │   │   │   └── schedule_page.dart          # ConsumerStatefulWidget + Form
│   │   │   └── widgets/
│   │   │       ├── ai_input_card.dart          # AI 占位
│   │   │       ├── title_field.dart
│   │   │       ├── description_field.dart
│   │   │       ├── datetime_picker_field.dart  # 时间选择 (date + time)
│   │   │       ├── repeat_rule_editor.dart     # 编排子编辑器
│   │   │       ├── weekday_selector.dart       # MO-SU 多选
│   │   │       ├── month_day_selector.dart     # 1-31 多选
│   │   │       ├── end_condition_editor.dart   # Never / Until / Count
│   │   │       └── reminder_selector.dart      # 0~1440 分钟
│   │   │
│   │   ├── calendar/                   # ★ 平台日历交互
│   │   │   ├── platform/
│   │   │   │   ├── calendar_platform.dart       # 抽象接口 (DIP)
│   │   │   │   └── calendar_method_channel.dart # MethodChannel 实现
│   │   │   └── service/                        # (预留: 跨平台业务编排)
│   │   │
│   │   └── ai/                         # ★ 零改动 AI 接入预留
│   │       ├── parser/                 # LLM JSON → Schedule
│   │       ├── service/                # HTTP / WebSocket 调用
│   │       └── prompt/                 # System Prompt 模板
│   │
│   └── shared/                         # 跨 Feature 通用
│       ├── widgets/                    # 通用 UI (未用，预留给 SnackBar 等)
│       ├── dialog/                     # 通用 Dialog
│       └── extension/
│           └── datetime_extension.dart # int.max / DateTime.combine
│
├── android/app/src/main/kotlin/com/example/ai_calendar/
│   ├── MainActivity.kt                 # register CalendarPlugin
│   ├── CalendarPlugin.kt               # MethodCallHandler + ActivityAware
│   ├── CalendarProvider.kt             # CalendarContract CRUD
│   ├── CalendarPermission.kt           # 运行时权限封装
│   └── RRuleBuilder.kt                 # RepeatRule JSON → RFC 5545 RRULE
│
└── test/
    └── widget_test.dart                # 烟雾测试
```

---

## 5. 核心数据模型

### 5.1 Schedule (全局唯一业务模型)

**所有子系统（AI / DB / HTTP / CalendarProvider）都围绕这个 Model 工作。**

```dart
class Schedule {
  final String title;              // 必填
  final String? description;       // 可选
  final DateTime start;            // 本地时间，toJson → UTC ISO8601
  final DateTime end;              // 本地时间，toJson → UTC ISO8601
  final int? reminderMinutes;      // 默认 15；null = 不提醒；0 = 开始时提醒
  final RepeatRule? repeatRule;    // null = 不重复
}
```

关键约束：

- Flutter 层 **绝不持有 RRULE String**，RepeatRule 对象是一等公民
- `toJson()` 走 UTC：`start.toUtc().toIso8601String()`
- `fromJson()` 转本地：`DateTime.parse(str).toLocal()`
- Immutable + `copyWith({clearRepeatRule: true})` 模式清空可空字段

### 5.2 RepeatRule + Frequency + Weekday

```dart
enum Frequency { none, daily, weekly, monthly, yearly }
enum Weekday { monday(1,'一','MO') ... sunday(7,'日','SU') }

class RepeatRule {
  final Frequency frequency;       // none 时 isRepeating=false
  final int interval;              // 默认 1；>1 才输出 INTERVAL
  final List<Weekday> byDay;       // 仅 weekly 时生效
  final List<int> byMonthDay;      // 仅 monthly 时生效
  final DateTime? until;           // 截止 (与 count 二选一)
  final int? count;                // 重复次数 (与 until 二选一)
}
```

**Flutter → Android JSON 传输格式** (`Schedule.toJson()`):

```json
{
  "title": "项目评审会",
  "description": "评审 v1.2",
  "start": "2026-08-06T07:00:00.000Z",
  "end": "2026-08-06T09:00:00.000Z",
  "reminderMinutes": 15,
  "repeatRule": {
    "frequency": "WEEKLY",
    "interval": 2,
    "byDay": ["MO", "WE"],
    "byMonthDay": [],
    "until": "2026-10-31T23:59:59.000Z",
    "count": null
  }
}
```

---

## 6. Riverpod 状态管理

### 6.1 Provider 链路

| Provider                     | 类型                                                         | 说明                                     |
| ---------------------------- | ------------------------------------------------------------ | ---------------------------------------- |
| `calendarPlatformProvider`   | `Provider<CalendarPlatform>`                                 | 生产=MethodChannel，测试可 override=Mock |
| `scheduleRepositoryProvider` | `Provider<ScheduleRepository>`                               | 接口注入                                 |
| `scheduleServiceProvider`    | `Provider<ScheduleService>`                                  | 业务规则                                 |
| `scheduleNotifierProvider`   | `StateNotifierProvider<ScheduleNotifier, ScheduleFormState>` | 表单状态                                 |

### 6.2 ScheduleFormState

```dart
class ScheduleFormState {
  final Schedule schedule;      // 单一数据源
  final bool isSubmitting;      // 防止重复点击
  final Object? error;          // Service 抛的异常 → UI 友好提示
  final String? lastCreatedEventId; // 成功提示 SnackBar
}
```

UI 更新状态的唯一入口：`ScheduleNotifier.updateXxx()`。直接改 `schedule.copyWith()` 再赋值是反模式。

---

## 7. 路由设计 (go_router)

| 路径        | 名称       | 说明                        |
| ----------- | ---------- | --------------------------- |
| `/`         | `schedule` | 创建日程 (MVP 唯一实现)     |
| `/history`  | `history`  | 历史记录（PlaceholderPage） |
| `/settings` | `settings` | 设置（PlaceholderPage）     |
| `/ai`       | `ai`       | AI 配置（PlaceholderPage）  |
| `/debug`    | `debug`    | 调试（PlaceholderPage）     |
| 其他        | error      | 404 (PlaceholderPage)       |

**新增页面方式：**

1. 在 `features/<name>/page/<name>_page.dart` 实现
2. 在 `app_router.dart` 的 `routes` 列表加一条 `GoRoute`
3. 无需修改其他任何模块

---

## 8. Flutter ↔ Android 通信 (MethodChannel)

### 8.1 常量约定

两处定义（保持一致）：

**Dart (`lib/core/constants/app_constants.dart`)**:

```dart
static const String calendarChannel = 'com.example.ai_calendar/calendar';
// + createSchedule / updateSchedule / deleteSchedule / querySchedules
// + requestPermissions / checkPermissions
```

**Kotlin (`CalendarPlugin.kt` 伴生对象)**:

```kotlin
private const val CHANNEL_NAME = "com.example.ai_calendar/calendar"
// + 6 个 METHOD_xxx 常量
```

### 8.2 所有方法签名

| Method               | Arguments                                | Returns                                                         |
| -------------------- | ---------------------------------------- | --------------------------------------------------------------- |
| `checkPermissions`   | —                                        | `Boolean`                                                       |
| `requestPermissions` | —                                        | `Boolean` (挂起 pendingResult，等待 onRequestPermissionsResult) |
| `createSchedule`     | `Schedule.toJson()` Map                  | `String` (eventId)                                              |
| `updateSchedule`     | `{eventId, schedule: Schedule.toJson()}` | `null`                                                          |
| `deleteSchedule`     | `{eventId}`                              | `null`                                                          |
| `querySchedules`     | `{start?, end?}`                         | `List<Map>` (MVP 返回 `[]`)                                     |

### 8.3 错误码约定

| Code                | 场景                          | UI 处理                 |
| ------------------- | ----------------------------- | ----------------------- |
| `BAD_ARGS`          | 参数格式校验失败              | 红 SnackBar："参数错误" |
| `BAD_DATA`          | 业务数据非法 (如 end < start) | 红 SnackBar：e.message  |
| `PERMISSION_DENIED` | SecurityException             | 引导用户去系统设置      |
| `UNEXPECTED`        | 未预期                        | 记录日志并提示          |

---

## 9. Android 端架构

依赖顺序（**禁止反向依赖**）：

```
MainActivity → CalendarPlugin → CalendarProvider
              CalendarPlugin → CalendarPermission
              CalendarPlugin → RRuleBuilder (纯函数，无依赖)
```

### 9.1 CalendarPermission.kt

- 只读 `READ_CALENDAR` + `WRITE_CALENDAR`（Manifest 已声明）
- `requestPermissions` 走系统弹框，requestCode = 1001
- 在 `CalendarPlugin.onRequestPermissionsResult` 中解锁 `pendingResult`

### 9.2 RRuleBuilder.kt（纯函数，零 Android 依赖，可单元测试）

```kotlin
RRuleBuilder.fromRepeatRuleMap({
    "frequency": "WEEKLY",
    "interval": 2,
    "byDay": ["MO","WE"],
    "until": "2026-10-31T23:59:59Z"
})
// ↓
"FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;UNTIL=20261031T235959Z"
```

支持字段（严格对应 CalendarContract.Events.RRULE RFC 5545）：

- ✅ FREQ：DAILY / WEEKLY / MONTHLY / YEARLY
- ✅ INTERVAL：>1 才输出
- ✅ BYDAY：MO, TU, WE, TH, FR, SA, SU
- ✅ BYMONTHDAY：1..31
- ✅ COUNT：正整数
- ✅ UNTIL：强制 `yyyyMMdd'T'HHmmss'Z'` UTC

**预留字段（后续加 RepeatRule 属性即可，builder 已可扩展）：**

- EXDATE（排除日期）
- RECURRENCE-ID（单次实例变更）
- BYMONTH
- WKST（一周起始日）

### 9.3 CalendarProvider.kt

**核心职责：只和 CalendarContract 对话，不解析业务对象。**

调用链路：

1. `ensureCalendarExists()`
   - 先 `findWritableCalendar()`：查询 `Calendars.VISIBLE=1`，取第一条
   - 找不到就 `createLocalCalendar()`：ACCOUNT_TYPE_LOCAL，颜色紫 (#FF6750A4 的负值)，带 `CALLER_IS_SYNCADAPTER`
2. `ContentResolver.insert(Events.CONTENT_URI, values)` → 返回 eventUri → eventId
3. 如果 reminderMinutes 非 null：`insert(Reminders.CONTENT_URI)`，METHOD = METHOD_ALERT（MINUTES=0 表示开始时提醒；null 不插入提醒）

Events 字段默认值：

- STATUS = STATUS_CONFIRMED
- SELF_ATTENDEE_STATUS = STATUS_CONFIRMED
- AVAILABILITY = AVAILABILITY_BUSY
- EVENT_TIMEZONE = TimeZone.getDefault().id

### 9.4 CalendarPlugin.kt

- 实现 `FlutterPlugin` + `ActivityAware`（权限必须 Activity）
- `onAttachedToActivity` 注册 `RequestPermissionsResultListener`
- `ScheduleDto` 是插件内私有数据类，**不与 Flutter 层共享类定义**（跨平台通信靠 JSON，避免耦合）

---

## 10. AI 接入（v1.1 已实现：DeepSeek V4 Flash）

### 10.1 调用约定

- 端点：`POST https://api.deepseek.com/chat/completions`（base_url 未变）
- 模型：`deepseek-v4-flash`（`deepseek-chat` / `deepseek-reasoner` 已于 2026-07-24 弃用）
- 协议：OpenAI ChatCompletions 兼容，`Authorization: Bearer <API Key>`
- 结构化输出：`response_format: {"type": "json_object"}`，system prompt 含 "json" 字样与 JSON 样例
- Key 优先级：应用内 SharedPreferences 保存的 Key > `--dart-define=AI_API_KEY`

### 10.2 文件清单

```
features/ai/
  prompt/system_prompt.dart     # 模板：强制输出固定 JSON Schema，相对时间→绝对时间
  parser/schedule_parser.dart   # fromLlmJson(Map) → Schedule（含容错/回退）
  service/ai_api_key_store.dart # SharedPreferences 持久化 Key
  service/ai_service.dart       # parse(naturalLanguage) → Schedule + 异常体系
  ai_providers.dart             # aiServiceProvider / aiHttpClientProvider / aiApiKeyStoreProvider
```

`ScheduleNotifier` 新增 `isParsing` / `aiError` 状态与 `fillFromAi()`：解析结果**只填充表单**，由用户核对后再提交，不直接写日历。

### 10.3 AiInputCard

已启用：输入 → 回车/发送 → DeepSeek 解析 → 填充表单；右上角钥匙图标可配置 API Key。

---

## 11. 权限设计

| 权限                 | Android 版本 | 授予时机                           |
| -------------------- | ------------ | ---------------------------------- |
| `READ_CALENDAR`      | All          | 用户首次点"创建日程"时             |
| `WRITE_CALENDAR`     | All          | 同上                               |
| `POST_NOTIFICATIONS` | 13+          | 同上（或创建首次提醒失败时再申请） |

授予路径：

1. `ScheduleNotifier.submit()`
2. → `ScheduleService.createSchedule()`
3. → `_ensurePermissions()`：先 `checkPermissions`，没过 `requestPermissions`
4. → `CalendarMethodChannel` invokeMethod → **挂起**
5. → 用户选"允许/拒绝"→ `CalendarPlugin.onRequestPermissionsResult` → `pendingResult.success(true/false)`
6. → MethodChannel 返回 → Service 继续或抛 `CalendarPermissionDeniedException`

---

## 12. MVP 未实现 / 预留接口

| 功能                   | 预留位置                                                     | 接入方式                                     |
| ---------------------- | ------------------------------------------------------------ | -------------------------------------------- |
| EXDATE                 | `RepeatRule.excludedDates` + `RRuleBuilder` 加 EXDATE 段     | 加 Widget + 加属性                           |
| Attendee 参会人        | `Schedule.attendees` + CalendarContract.Attendees 表         | 加 Widget + CalendarProvider.insertAttendees |
| BYMONTH / WKST         | RepeatRule 加字段                                            | RRuleBuilder 加几行                          |
| querySchedules MVP     | CalendarPlugin 返回 `[]`                                     | 写 Cursor → Schedule.fromJson                |
| 通知渠道               | (android O+)                                                 | CalendarReminders 配置 + NotificationChannel |
| 本地持久化（离线草稿） | `features/schedule/repository/` 加 `LocalScheduleRepository` | Decorator 模式包装远程                       |
| 多语言 (i18n)          | `core/l10n/` + intl                                          | arb 文件                                     |

---

## 13. 编码规范

### Dart

- 官方 `dart format` + `flutter_lints: ^5.0.0`
- **所有 Model immutable**，用 `final` + `copyWith` 可空字段支持 `clearXxx: true` 参数
- `==` / `hashCode` 必须重写（用 `Object.hashAll`）
- 异步函数必须 `mounted` check 后操作 BuildContext
- Riverpod 读用 `ref.read`（回调内），看用 `ref.watch`（build 内）

### Kotlin

- 使用 `object` 单例（CalendarProvider / CalendarPermission / RRuleBuilder）
- `ContentResolver` 操作全包裹 `try { ... } catch (se: SecurityException)`
- `Cursor` 用 `.use { }` 自动关闭
- UNTIL 时区强制 UTC

---

## 14. 验证清单（上线前检查）

- [ ] `flutter analyze` → 0 issues
- [ ] `flutter test` → All passed
- [ ] Android 6.0 / 13 / 14 三版本真机测试权限流
- [ ] 验证日程创建后 3 次提醒都响（一次、隔天、一周后）
- [ ] RRULE 在 Google Calendar App 中打开时能看到"重复规则"
- [ ] 卸载重装 App，`ensureCalendarExists()` 不会创建重复日历
- [ ] 断网下能创建（纯系统 Provider，不依赖网络）

---

## 15. 未来架构演进路线图

1. **v1.1 AI 接入**：`features/ai/` 完成，`AiInputCard` 可用
2. **v1.2 历史记录页**：`/history`，`querySchedules` 实现，`ScheduleListTile` 通用组件
3. **v1.3 草稿离线**：`Drift`/`Isar` 本地持久化，Repository 变成 Remote + Local 双源
4. **v1.4 多端扩展**：`CalendarIOSPlatform` (EventKit)，`CalendarWebPlatform` (Google Calendar API)
5. **v2.0 插件化**：`CalendarPlatform` 做成 Federated Plugin，Android / iOS / Web 分离 package
