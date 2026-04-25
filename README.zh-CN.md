<div align="center">

# vibe-beeper

**一个漂浮在 macOS 桌面上的 Agent 状态提醒器，面向 Claude Code 与 Codex。**

*不用一直盯着终端，也不错过完成、报错、权限请求和输入提问。*

<img src="assets/hero.gif" width="320" alt="vibe-beeper 演示">

<br><br>

[English](README.md)

</div>

---

## 这是什么

你在 Claude Code 或 Codex 里启动一个任务，然后切去写代码、开会、看文档。几分钟之后，Agent 可能已经：

- 做完了
- 卡在权限确认
- 在等你回答问题
- 但你的终端早就被埋在窗口堆里

vibe-beeper 的作用，就是把这些状态直接提到桌面层。它会用一个 LCD 风格挂件、菜单栏图标、全局快捷键和可选语音能力，把 Agent 的关键信息从终端里“拎出来”。

---

## 当前支持情况

| Provider | 状态 | 说明 |
| --- | --- | --- |
| Claude Code | 稳定可用 | hooks、状态同步、权限提醒、自动批准、语音输入、朗读都已可用 |
| Codex | 基础接入 | 已有探测、配置标记、事件翻译和 UI 状态入口，仍在持续补齐 |

如果你的主要工作流是 Claude Code，这个项目已经能正常使用。Codex 路径目前适合尝鲜和基础提醒，不建议当作完全等价集成来理解。

---

## 功能特性

### 桌面状态提醒

vibe-beeper 会跟踪 8 种 Agent 状态，并按优先级展示最需要你关注的那个：

| 状态 | 预览 | 含义 |
| --- | --- | --- |
| **SNOOZING** | <img src="assets/states/snoozing.png" width="200"> | 当前没有活跃会话 |
| **WORKING** | <img src="assets/states/working.png" width="200"> | Agent 正在执行工具或任务 |
| **DONE!** | <img src="assets/states/done.png" width="200"> | 任务已完成 |
| **ERROR** | <img src="assets/states/error.png" width="200"> | 任务执行失败 |
| **ALLOW?** | <img src="assets/states/allow.png" width="200"> | 正在等待你批准权限请求 |
| **INPUT?** | <img src="assets/states/input.png" width="200"> | Agent 在等你输入 |
| **LISTENING** | <img src="assets/states/listening.png" width="200"> | 正在录音，准备语音输入 |
| **RECAP** | <img src="assets/states/recap.png" width="200"> | 正在朗读回复摘要 |

### 权限与自动批准

你可以在四种模式之间切换：

| 模式 | 行为 |
| --- | --- |
| **Strict** | 每次都询问 |
| **Relaxed** | 自动允许读取，写入和命令执行前询问 |
| **Trusted** | 自动允许文件操作，shell 命令前询问 |
| **YOLO** | 自动批准所有请求 |

`YOLO` 风险很高，会直接影响写文件、删文件、执行命令等行为，只适合你明确知道后果时使用。

### 语音输入与朗读

- **WhisperKit**：本地语音转文字
- **Apple Speech**：系统内置备用识别
- **Kokoro**：本地 TTS 朗读
- **Apple Speech**：系统朗读备用路径
- `⌥R` 可随时开始或停止录音
- 可选双击掌启动语音输入

### 外观与反馈

- 10 种外壳主题色
- 3 种显示模式：大号、紧凑、仅菜单栏
- 声音提醒、完成提示音、振动反馈
- 菜单栏图标会跟随当前状态变化

![Shell colors](assets/shell-colors.png)

---

## 安装

### 环境要求

- macOS 14 Sonoma 或更新版本
- Claude Code CLI，用于完整可用路径
- Codex CLI，如果你想启用 Codex 集成
- Xcode Command Line Tools / Swift 6，如果你要从源码构建

### 方式一：直接安装发布版

1. 前往 [Releases](https://github.com/zqxsober/vibe-beeper/releases) 下载最新版。
2. 把 `vibe-beeper.app` 拖到 `/Applications`。
3. 启动应用。
4. 按照首次引导完成 hooks、主题、权限、语音模型和快捷键配置。

这是最适合普通用户的安装方式。

### 方式二：从源码构建

```bash
git clone https://github.com/zqxsober/vibe-beeper.git
cd vibe-beeper
swift test
SKIP_INSTALL=1 ./build.sh
open vibe-beeper.app
```

说明：

- `SKIP_INSTALL=1 ./build.sh` 只会在仓库目录生成本地 `.app`，不会覆盖 `/Applications`。
- 直接运行 `./build.sh` 会更新 `/Applications/vibe-beeper.app`。
- `make install` 会构建 app、安装 Claude hooks，并尝试启动应用。

---

## 首次启动建议流程

推荐按下面顺序完成初始化：

1. 检测 Claude Code / Codex CLI 是否存在
2. 安装 Claude Code hooks
3. 如果检测到 Codex，并且你需要它，就安装 Codex hooks
4. 授予辅助功能、麦克风、语音识别等权限
5. 按需下载 WhisperKit 和 Kokoro 模型
6. 选择外壳主题、挂件尺寸、自动批准模式和快捷键
7. 如果 hooks 是中途新装的，重启已打开的 Claude Code / Codex 会话

后续如果状态不同步、hooks 失效或权限变化，可以到 **Settings → Setup** 里重新安装 hooks 或重新跑 onboarding。

---

## 日常使用

### 处理权限请求

- 可以直接点大号挂件上的按钮
- 也可以使用全局快捷键：
  - `⌥A` 批准
  - `⌥D` 拒绝

### 语音工作流

- `⌥R` 开始或停止语音输入
- `⌥M` 停止朗读或重播语音
- 开启后可用双击掌触发录音

### 快速回到终端

- `⌥T` 聚焦当前终端
- 挂件和菜单栏的定位是“减少来回切终端”，不是替代终端本身

### 菜单栏里能做什么

菜单栏入口可以管理：

- 当前状态查看
- 静音 / 取消静音
- 睡眠 / 唤醒
- 双击掌开关
- 自动批准模式切换
- 挂件尺寸切换
- 打开设置、修复 hooks、重新引导

---

## 开发常用命令

```bash
swift test                     # 跑测试
SKIP_INSTALL=1 ./build.sh      # 只生成本地 app 包
make install                   # 构建、安装 Claude hooks、启动 app
make uninstall                 # 卸载 hooks 并停止 app
make dmg                       # 生成 DMG
```

补充说明：

- `scripts/setup.py` 会把 Claude hooks 写入 `~/.claude/settings.json`
- Codex 集成通过 app 内 onboarding / settings 管理
- `scripts/uninstall.py` 会移除项目写入的 Claude / Codex 本地配置痕迹

---

## 它是怎么工作的

### 本地事件传输

vibe-beeper 在 `127.0.0.1` 上监听本地事件，CLI hooks 把状态通过本机回传给桌面应用，不依赖云端中转。

### Claude Code

Claude 的 hooks 配置写入：

```text
~/.claude/settings.json
```

相关脚本和 IPC 信息位于：

```text
~/.claude/hooks
~/.claude/cc-beeper
```

### Codex

Codex 的配置标记和 hook 元数据位于本地用户目录：

```text
~/.codex/config.toml
~/.codex/hooks.json
```

### 多会话优先级

如果同时有多个会话，vibe-beeper 会展示优先级最高的状态，避免“一个低优先级完成提示把更重要的权限请求盖掉”。

---

## 隐私说明

> **默认设计就是尽量只在你的 Mac 本机完成。**

- 无遥测
- 无分析上报
- 无账号登录
- 无强制云服务依赖
- 本地语音识别和朗读优先
- 本地 hooks 配置可随时检查或移除

---

## 风险与边界

- `YOLO` 会自动批准高风险操作，请谨慎使用
- Codex 路径仍在持续完善中
- 如果是在 hooks 安装前就已经打开的 CLI 会话，通常需要重启后才会完整生效

---

## 贡献

欢迎提 issue、提文档改进、报 bug 和发 PR。

推荐流程：

1. Fork 仓库
2. 创建分支
3. 先跑 `swift test`
4. 提交改动
5. 发起 Pull Request

---

## 声明

vibe-beeper 是一个独立的开源项目，与 Anthropic、OpenAI 没有官方隶属、背书或赞助关系。

它延续自 CC-Beeper 这一类桌面 Agent 提醒器思路，并继续沿着社区维护方向演进。

---

## 许可证

GPL-3.0，详见 [LICENSE](LICENSE)。

---

<div align="center">

Open Source · Native macOS · 面向高频 Agent 工作流

如果它帮你少错过一次权限确认，欢迎给项目点个 Star。

</div>
