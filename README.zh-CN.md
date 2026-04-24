<div align="center">

# Vibe-Beeper

**一个漂浮在 macOS 桌面上的 Agent 状态提醒器，面向 Claude Code 与 Codex。**

*不用一直盯着终端，也不错过任何一次完成、报错或权限请求。*

<img src="assets/hero.gif" width="320">

<br><br>

[English](README.md)

</div>

---

## 为什么需要它

你在 Claude Code 或 Codex 里启动一个任务，然后切去写代码、看文档、处理别的窗口。几分钟后，Agent 可能已经完成、报错，或者正在等你批准一个操作，但终端早就被埋在窗口堆里。

Vibe-Beeper 把这些状态提到桌面层：它会显示当前 Agent 是否在工作、是否完成、是否出错、是否需要输入或权限确认。你可以从桌面挂件或菜单栏里快速响应，不必频繁切回终端。

---

## 当前支持状态

| Provider | 状态 | 说明 |
| --- | --- | --- |
| Claude Code | 已支持 | 支持 hooks、状态同步、权限提醒、自动批准、语音输入与播报 |
| Codex | 基础接入中 | 已加入探测、配置标记、事件翻译和 UI 状态入口；完整 hook 写入与审批回包仍在后续阶段 |

> Codex 支持还不是 Claude Code 的完全等价实现。当前阶段的重点是多 Provider 架构和基础事件管线。

---

## 功能特性

### 实时状态

Vibe-Beeper 会用桌面 LCD 风格状态展示当前 Agent 的运行情况，并按优先级处理多个并发会话。

| 状态 | 说明 |
| --- | --- |
| **SNOOZING** | 当前没有活跃会话 |
| **WORKING** | Agent 正在执行工具或处理任务 |
| **DONE!** | 任务已完成 |
| **ERROR** | 执行过程中出现错误 |
| **ALLOW?** | 需要你批准权限请求 |
| **INPUT?** | Agent 正在等待你的输入 |
| **LISTENING** | 正在录音，用于语音输入 |
| **RECAP** | 正在朗读上一段回复或摘要 |

### 权限与自动批准

Claude Code 路径目前支持四种权限模式：

| 模式 | 行为 |
| --- | --- |
| **Strict** | 每次都询问，未经批准不执行 |
| **Relaxed** | 读取操作自动允许，写入和命令执行前询问 |
| **Trusted** | 文件操作自动允许，shell 命令前询问 |
| **YOLO** | 自动批准所有请求，包括文件修改、删除、命令执行和网络相关操作 |

YOLO 模式风险很高，只适合你完全信任当前任务和工作区时使用。

### 语音能力

你可以用全局快捷键或双击掌触发语音输入，把语音转成文本并注入当前终端。

- **WhisperKit**：本地运行，支持多语言，无需 API key
- **Apple Speech**：系统内置备用方案
- 支持 Terminal.app、iTerm2、Warp、Alacritty、Kitty、WezTerm 等常见终端

任务完成后，Vibe-Beeper 也可以朗读摘要：

- **Kokoro**：本地语音合成
- **Apple Speech**：系统备用朗读方案

### 全局快捷键

| 快捷键 | 作用 |
| --- | --- |
| **Option + A** | 批准当前权限请求 |
| **Option + D** | 拒绝当前权限请求 |
| **Option + R** | 开始或停止语音录入 |
| **Option + T** | 聚焦当前终端 |
| **Option + M** | 静音、停止朗读或重播上一段摘要 |

所有快捷键都可以在设置里修改。

### 外观与反馈

- 10 种外壳主题色
- 3 种挂件尺寸：大号、紧凑、仅菜单栏
- 声音提醒、完成提示音、振动反馈
- 菜单栏图标会根据当前状态变化

---

## 安装与使用

### 环境要求

- macOS 14 Sonoma 或更高版本
- Claude Code CLI
- Codex CLI，若要启用 Codex 基础接入

### 使用步骤

1. 下载最新版本或从源码构建。
2. 将 `vibe-beeper.app` 放到 `/Applications`。
3. 启动应用，按照引导完成 CLI 检测、hooks 安装、权限授权、语音模型和快捷键设置。
4. 如果已经有正在运行的 Claude Code 或 Codex 会话，建议重启对应 CLI 会话，让新 hook 配置生效。

从源码构建：

```bash
swift build
```

生成本地 `.app` bundle：

```bash
SKIP_INSTALL=1 ./build.sh
```

---

## 隐私说明

Vibe-Beeper 默认走本地通信，不需要账号，也不需要 API key。

- hooks 通过 `127.0.0.1` 发送到本地 HTTP 服务
- 不包含遥测、分析或崩溃上报
- WhisperKit 和 Kokoro 都在本机运行
- 语音不会上传到云端
- Claude hooks 可以在 `~/.claude/settings.json` 中检查或移除
- Codex 配置标记位于 `~/.codex/config.toml`

---

## 技术细节

### Provider 架构

项目正在从单一 Claude Code 集成演进为多 Provider 架构。

核心抽象包括：

- `ProviderKind`：区分 Claude Code 和 Codex
- `AgentState`：统一 LCD 状态
- `AgentEvent`：统一事件模型
- `SessionStore`：按 Provider 和 Session 聚合状态
- `LocalHTTPHookServer`：Provider 无关的本地 HTTP 传输层

Claude Code 现有逻辑被迁移到：

```text
Sources/Monitor/Providers/Claude
```

Codex 基础接入位于：

```text
Sources/Monitor/Providers/Codex
```

### Hook 工作方式

Claude Code 会把关键事件通过 hooks 发给本地 HTTP 服务，例如：

- `UserPromptSubmit`
- `PreToolUse`
- `PostToolUse`
- `Notification`
- `PermissionRequest`
- `Stop`
- `StopFailure`

本地服务会把不同 provider 的原始 payload 转成统一事件，再驱动桌面状态、菜单栏状态和权限弹窗。

### 多会话状态

Vibe-Beeper 支持多个并发会话。最终展示状态按优先级聚合：

```text
ERROR > ALLOW? > INPUT? > LISTENING > RECAP > WORKING > DONE! > SNOOZING
```

这可以避免某个低优先级完成事件覆盖掉另一个正在等待你处理的权限请求。

---

## 风险提示

自动批准能力会直接影响本地文件、命令执行和网络访问。

尤其是 YOLO 模式，会自动批准高风险操作。使用前请确认：

- 当前仓库是可信的
- Agent 的任务边界是清晰的
- 没有未备份的重要文件
- 你理解自动批准可能造成的后果

Codex 支持仍在逐步完善中，当前更适合用于基础状态提醒和事件管线验证，不建议把它当成完整权限代理。

---

## 贡献

欢迎提交 issue、建议和 pull request。

推荐流程：

1. Fork 仓库
2. 创建功能分支
3. 提交改动
4. 打开 Pull Request

---

## 许可证

GPL-3.0，详情见 [LICENSE](LICENSE)。

---

<div align="center">

Free · Open Source · Native macOS

如果它帮你少错过一次权限确认，记得给项目点个 Star。

</div>
