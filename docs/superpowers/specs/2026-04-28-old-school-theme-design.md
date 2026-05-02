# Old School Theme Design

Date: 2026-04-28
Status: User review

## 1. 需求分析

用户希望基于参考图，为 vibe-beeper 新增一套名为 `old school` 的主题。该主题需要完全保留 App 原有功能，只改变主浮窗和设置页主题区域的布局与视觉风格。旧主题必须继续保留，不能被替换或降级。

本次范围选择为 B + C：

- 覆盖主浮窗的大尺寸和紧凑尺寸外观。
- 覆盖设置页中的主题预览、主题选择和 old school 专属尺寸档位。
- 保留现有全局显示模式：`Large`、`Compact`、`Menu only`。
- 新增 old school 专属大窗口尺寸档位：`Small`、`Medium`、`Large`、`Showcase`。
- 不新增统计页、关于页、设置页子功能或其它业务功能。

## 2. 设计目标

- `old school` 主题呈现复古米色老式 Macintosh 风格：米色塑料外壳、凹陷黑色屏幕边框、绿色单色 LCD、像素小人、彩虹徽标、软驱槽、红色状态灯和老式按键。
- 旧主题继续使用现有外壳图片、按钮、窗口尺寸和行为。
- 用户选择 `old school` 后，可以在设置页选择大窗口的视觉尺寸档位。
- 所有按钮仍调用原有逻辑，不改变权限确认、录音、停止朗读和回到终端的行为。
- 新主题实现应尽量隔离，避免把大量主题判断塞进现有 `ContentView` 和 `CompactView`。

## 3. 架构设计

新增 old school 主题时，沿用现有主题系统入口：

```text
ThemeManager
 ├─ 原有主题：black / blue / green / mint / orange / pink / purple / red / white / yellow / apple
 └─ 新主题：old-school
```

视图层采用主题分支：

```text
CCBeeperApp
 └─ 根据 monitor.widgetSize 和 themeManager.theme 选择主窗口内容
     ├─ 旧主题 Large    → ContentView
     ├─ 旧主题 Compact  → CompactView
     ├─ old school Large   → OldSchoolLargeView
     └─ old school Compact → OldSchoolCompactView
```

这样做的原因是 `old school` 和现有 beeper 外壳比例差异较大。独立视图能降低回归风险，也便于后续单独调尺寸、间距、按钮和屏幕比例。

## 4. 模块划分

实现时按以下模块边界组织代码：

```text
Sources/Theme/ThemeManager.swift
 ├─ 新增 ShellTheme(id: "old-school", displayName: "Old School")
 ├─ 新增 isOldSchoolTheme
 └─ 新增 oldSchoolDisplaySize 读取或由独立设置对象管理

Sources/Widget/OldSchoolChrome.swift
 ├─ OldSchoolLCDHeader
 ├─ OldSchoolScreenFrame
 ├─ OldSchoolDriveSlot
 ├─ OldSchoolRainbowBadge
 ├─ OldSchoolKeyButton
 └─ OldSchoolControls

Sources/Widget/OldSchoolLargeView.swift
 └─ 复古整机大窗口布局

Sources/Widget/OldSchoolCompactView.swift
 └─ 复古迷你紧凑布局

Sources/Settings/SettingsGeneralSection.swift
 ├─ old school 主题预览
 └─ Old School Size 分段选择器
```

`OldSchoolLargeView`、`OldSchoolCompactView` 和 chrome 小组件保持独立类型。实现时可以按文件数量做轻微合并，但不能把 old school 的布局逻辑直接堆进旧主题视图。

## 5. 主浮窗图纸

大尺寸 `old school` 使用老 Mac 整机布局，默认 `Medium` 档约 `420 x 320`：

```text
┌────────────────────────── 复古米色 Mac 外壳 ──────────────────────────┐
│  ┌──────────────────────── 凹陷屏幕边框 ───────────────────────────┐  │
│  │   VIBE-BEEPER                                                  │  │
│  │ ┌──────────────────── 绿色单色 LCD ───────────────────────────┐ │  │
│  │ │ [像素小人]  摸鱼中 / WORKING...          [RELAXED 徽章]     │ │  │
│  │ │              省电模式 · 0s / tool detail                     │ │  │
│  │ └─────────────────────────────────────────────────────────────┘ │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│   彩虹徽标             软驱槽 + 红色状态灯                            │
│                                                                       │
├────────────────────────── 键盘/底座区域 ───────────────────────────────┤
│ [允许] [拒绝] [录音/停止] [停止朗读] [回到终端]                         │
└───────────────────────────────────────────────────────────────────────┘
```

视觉要求：

- 背景为透明窗口，主体是米色外壳。
- 外壳有轻微倒角、内阴影和塑料质感。
- 屏幕区域使用绿色单色 LCD，保留现有像素角色、标题、详情文案、徽章和滚动详情。
- LCD 上方显示 `VIBE-BEEPER` 标识。
- 按钮使用老式键盘按键外观，按下时有轻微下沉反馈。
- `old school` 不直接复用现有彩色按钮 PNG。

## 6. 紧凑图纸

`Compact` 保持全局模式语义，不受 `Old School Size` 影响。窗口尺寸固定为 `310 x 200`。

```text
┌──────────── 迷你复古机身 ────────────┐
│ ┌──────── 绿色 LCD ───────────────┐ │
│ │ [像素小人] 摸鱼中    [徽章图标] │ │
│ │ 省电模式 · 0s                   │ │
│ └─────────────────────────────────┘ │
│ 彩虹徽标            软驱槽 + LED     │
└─────────────────────────────────────┘
```

紧凑模式不显示按键行，继续依赖热键和菜单交互。这与当前 `Compact` 的功能定位一致。

## 7. 设置页图纸

设置页继续放在现有 `Theme` tab 中，不新增独立 tab。

```text
Shell Theme
┌──────────────────────────────────────────────┐
│ [old school 预览图]   Old School             │
│                    retro Mac shell           │
│                                              │
│ 主题点：● ● ● ● ● ● ● ● ● ● ● ◉             │
│                                              │
│ Old School Size                              │
│ [Small] [Medium ✓] [Large] [Showcase]        │
└──────────────────────────────────────────────┘
```

显示规则：

- 当前主题不是 `old-school` 时，不显示 `Old School Size`。
- 当前主题是 `old-school` 时，显示尺寸分段选择器。
- 切走旧主题时，不清空 old school 尺寸档位；下次切回时恢复之前选择。

## 8. 数据模型

保留现有全局显示模式：

```swift
enum WidgetSize: String, CaseIterable, Equatable {
    case large
    case compact
    case menuOnly
}
```

新增 old school 专属大窗口档位：

```swift
enum OldSchoolDisplaySize: String, CaseIterable, Equatable {
    case small
    case medium
    case large
    case showcase
}
```

窗口尺寸：

```text
Small     360 x 270
Medium    420 x 320
Large     500 x 380
Showcase  580 x 440
```

持久化：

```text
themeId                 已有，新增值 old-school
widgetSize              已有，继续使用
oldSchoolDisplaySize    新增，默认 medium
```

## 9. 核心流程

主题切换流程：

```text
用户在设置页选择 old school
        ↓
ThemeManager.currentThemeId = "old-school"
        ↓
主窗口根据当前 widgetSize 渲染 OldSchoolLargeView 或 OldSchoolCompactView
        ↓
如果 widgetSize == .large，根据 oldSchoolDisplaySize 计算窗口尺寸
```

尺寸切换流程：

```text
用户在设置页选择 Small / Medium / Large / Showcase
        ↓
保存 oldSchoolDisplaySize
        ↓
如果当前 theme == old-school 且 widgetSize == .large
        ↓
resizeMainWindow(to:)
        ↓
OldSchoolLargeView 按新尺寸重排
```

状态渲染流程：

```text
monitor.state
 ├─ 控制像素角色动画
 ├─ 控制 LCD 标题和详情文案
 ├─ 控制 LED 闪烁
 └─ 控制注意态视觉反馈

monitor.currentPreset
 └─ 控制 LCD 右侧 badge
```

## 10. 功能映射

`old school` 的所有交互必须继续使用现有逻辑：

```text
允许按键       → monitor.respondToPermission(allow: true)
拒绝按键       → monitor.respondToPermission(allow: false)
录音按键       → monitor.voiceService.toggle()
停止朗读按键   → monitor.ttsService.stopSpeaking()
回到终端按键   → monitor.goToConversation()
状态变化       → 现有 BuzzService / LED / LCD 状态逻辑
```

按钮启用规则保持现状：

- 权限确认按键只在 `monitor.state.needsAttention` 时可用。
- 录音按键始终可用。
- 停止朗读按键只在 TTS 正在朗读时可用。
- 回到终端按键保持可用。

## 11. 技术选型

推荐优先使用 SwiftUI 绘制 old school 外观，而不是先生成 PNG 外壳资源。

原因：

- 尺寸档位有四档，SwiftUI 绘制更容易按比例缩放。
- LCD、按钮、LED 和阴影需要动态响应状态。
- 可以减少多套 PNG 资产生成和对齐成本。

可接受的混合方式：

- 彩虹徽标可以用 SwiftUI shape 或小型绘制组件。
- 如果 SwiftUI 外壳质感不足，再补充脚本生成 PNG 外壳，但仍应保留动态内容在 SwiftUI 中渲染。

## 12. 风险点

- **窗口尺寸风险**：old school 比当前 beeper 高，可能遮挡用户桌面。用尺寸档位缓解，默认使用 `Medium`。
- **状态信息拥挤**：小档位和紧凑模式中，LCD 内容可能放不下。需要保留 `MarqueeText` 或缩短徽章显示。
- **旧主题回归风险**：窗口尺寸计算如果全局改动过大，可能影响旧主题。实现时应集中封装尺寸判断并补测试。
- **设置复杂度风险**：同时存在全局 `WidgetSize` 和 old school 专属尺寸，设置页文案要清楚说明作用范围。
- **性能风险**：SwiftUI 绘制阴影、网格和动画过多可能增加开销。需要控制阴影层级，避免高频重绘大面积复杂 Canvas。

## 13. 验证标准

实现完成后需要验证：

- `ThemeManager.themes` 包含 `old-school`，旧主题仍存在。
- 旧主题 `Large` 和 `Compact` 窗口尺寸保持现状。
- `old-school + Large` 下，四个 old school 尺寸档位能保存、恢复并触发窗口尺寸变化。
- `old-school + Compact` 不受 old school 大窗口尺寸档位影响。
- `Menu only` 行为保持现状，不显示主窗口。
- 设置页只有在当前主题为 `old-school` 时显示 `Old School Size`。
- 权限确认、拒绝、录音、停止朗读和回到终端按钮仍调用原功能。
- LCD 状态文案、中英文运行文案、像素角色和徽章继续正常显示。
- 至少运行现有 Swift 测试中与主题、窗口尺寸、设置布局相关的测试。

## 14. 非目标

本次不做以下内容：

- 不新增统计页。
- 不新增关于页视觉改版。
- 不改 onboarding 整体流程，除非实现时需要让主题选择预览能显示 old school。
- 不移除或重命名旧主题。
- 不自动提交或推送代码。
