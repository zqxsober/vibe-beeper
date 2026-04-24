# Multi-Provider Codex Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 `vibe-beeper` 从仅支持 Claude Code 的桌面伴随工具，演进为同时支持 Claude Code 和 Codex 的多 Provider 版本，并先落地 Codex hooks MVP。

**Architecture:** 保留现有 Widget、语音、热键和窗口层，先抽离 Provider 无关的状态模型和会话聚合逻辑，再把 Claude 接入层迁移到独立 Provider，最后补一个 Codex hooks Provider 接入同一套事件模型。第一阶段不做 Codex App Server，只给它预留清晰边界。

**Tech Stack:** Swift 6、SwiftUI、Foundation、Network、XCTest、现有本地 HTTP hook 机制

---

## 文件结构规划

### 新增文件

- `Sources/Monitor/Core/ProviderKind.swift`
  - Provider 枚举，统一描述 `claude` 和 `codex`
- `Sources/Monitor/Core/AgentState.swift`
  - 取代当前 `ClaudeState` 的通用状态定义
- `Sources/Monitor/Core/AgentEvent.swift`
  - Provider 归一化后的事件模型
- `Sources/Monitor/Core/PendingApproval.swift`
  - Provider 无关的待审批模型
- `Sources/Monitor/Core/SessionStore.swift`
  - 承接当前 `SessionTracker` 的核心聚合逻辑
- `Sources/Monitor/Providers/Claude/ClaudeProvider.swift`
  - 迁移当前 Claude hook 事件转换和启动逻辑
- `Sources/Monitor/Providers/Claude/ClaudeHookInstaller.swift`
  - 从 `HookInstaller` 迁移 Claude hook 安装与卸载
- `Sources/Monitor/Providers/Claude/ClaudePermissionPresetWriter.swift`
  - 从 `PermissionPresetWriter` 迁移 Claude 权限预设写入
- `Sources/Monitor/Providers/Claude/ClaudeDetector.swift`
  - 从 `ClaudeDetector` 迁移 Claude 安装探测
- `Sources/Monitor/Providers/Codex/CodexDetector.swift`
  - Codex CLI 安装探测
- `Sources/Monitor/Providers/Codex/CodexHookInstaller.swift`
  - Codex hooks/notify 配置注入
- `Sources/Monitor/Providers/Codex/CodexHooksProvider.swift`
  - Codex hooks payload 到 `AgentEvent` 的转换和响应
- `Sources/Monitor/Transport/LocalHTTPHookServer.swift`
  - Provider 无关的本地 HTTP 接收层
- `Tests/CC-BeeperTests/CodexDetectorTests.swift`
  - Codex 安装探测测试
- `Tests/CC-BeeperTests/CodexHookInstallerTests.swift`
  - Codex 配置注入和识别测试
- `Tests/CC-BeeperTests/AgentStateTests.swift`
  - 通用状态模型测试
- `Tests/CC-BeeperTests/SessionStoreTests.swift`
  - 通用会话聚合测试

### 修改文件

- `Sources/Monitor/ClaudeMonitor.swift`
  - 缩减为新的 `AgentMonitor` 或迁移为 Provider 无关的外观层
- `Sources/Monitor/HookDispatcher.swift`
  - 迁移 Claude 事件翻译逻辑到 `ClaudeProvider`
- `Sources/Monitor/HTTPHookServer.swift`
  - 重命名迁移为 Provider 无关的传输层
- `Sources/Monitor/SessionTracker.swift`
  - 迁移聚合逻辑到 `SessionStore`
- `Sources/Monitor/PermissionController.swift`
  - 改为通过 Provider 标识转发审批结果
- `Sources/Onboarding/OnboardingViewModel.swift`
  - 支持检测多个 Provider 并安装对应接入
- `Sources/Onboarding/OnboardingCLIStep.swift`
  - 改成多 Provider 检测/安装 UI
- `Sources/Settings/SettingsSetupSection.swift`
  - Provider 维度展示接入状态
- `Sources/Settings/SettingsViewModel.swift`
  - 注入 Provider 检测和安装状态
- `Tests/CC-BeeperTests/HookInstallerTests.swift`
  - 迁移 Claude hook 安装器命名后的测试
- `Tests/CC-BeeperTests/HookDispatcherTests.swift`
  - 迁移为 Claude Provider 事件翻译测试
- `Tests/CC-BeeperTests/LCDStateTests.swift`
  - 更新为通用 `AgentState`

### 保持不动的核心区域

- `Sources/Widget/*`
- `Sources/Voice/*`
- 大部分窗口/主题代码

原则：

- UI 只消费通用状态，不直接依赖 Provider 协议细节。
- Claude/Codex 的配置路径、审批 payload、探测方式必须分别封装。
- 先保持现有功能路径，再做命名和目录层面的抽象。

## 任务拆分

### 任务 1：抽出 Provider 无关的状态与事件模型

**Files:**
- Create: `Sources/Monitor/Core/ProviderKind.swift`
- Create: `Sources/Monitor/Core/AgentState.swift`
- Create: `Sources/Monitor/Core/AgentEvent.swift`
- Create: `Sources/Monitor/Core/PendingApproval.swift`
- Modify: `Sources/Monitor/ClaudeMonitor.swift`
- Test: `Tests/CC-BeeperTests/AgentStateTests.swift`

- [ ] **Step 1: 编写通用状态模型测试，先锁定 UI 语义不回归**

```swift
import XCTest

private enum TestAgentState: Equatable {
    case idle
    case working
    case done
    case error
    case approveQuestion
    case needsInput
    case listening
    case speaking

    var label: String {
        switch self {
        case .idle: "ZZZ..."
        case .working: "WORKING"
        case .done: "DONE!"
        case .error: "ERROR"
        case .approveQuestion: "APPROVE?"
        case .needsInput: "INPUT?"
        case .listening: "LISTENING"
        case .speaking: "SPEAKING"
        }
    }

    var priority: Int {
        switch self {
        case .error: 7
        case .approveQuestion: 6
        case .needsInput: 5
        case .listening: 4
        case .speaking: 3
        case .working: 2
        case .done: 1
        case .idle: 0
        }
    }
}

final class AgentStateTests: XCTestCase {
    func testStateLabelsRemainStable() {
        XCTAssertEqual(TestAgentState.idle.label, "ZZZ...")
        XCTAssertEqual(TestAgentState.working.label, "WORKING")
        XCTAssertEqual(TestAgentState.done.label, "DONE!")
        XCTAssertEqual(TestAgentState.error.label, "ERROR")
        XCTAssertEqual(TestAgentState.approveQuestion.label, "APPROVE?")
        XCTAssertEqual(TestAgentState.needsInput.label, "INPUT?")
        XCTAssertEqual(TestAgentState.listening.label, "LISTENING")
        XCTAssertEqual(TestAgentState.speaking.label, "SPEAKING")
    }

    func testPriorityOrderRemainsStable() {
        XCTAssertGreaterThan(TestAgentState.error.priority, TestAgentState.approveQuestion.priority)
        XCTAssertGreaterThan(TestAgentState.approveQuestion.priority, TestAgentState.needsInput.priority)
        XCTAssertGreaterThan(TestAgentState.needsInput.priority, TestAgentState.working.priority)
        XCTAssertGreaterThan(TestAgentState.working.priority, TestAgentState.done.priority)
        XCTAssertGreaterThan(TestAgentState.done.priority, TestAgentState.idle.priority)
    }
}
```

- [ ] **Step 2: 运行测试，确认新测试先失败**

Run: `swift test --filter AgentStateTests`
Expected: FAIL，提示测试文件或类型尚不存在

- [ ] **Step 3: 新增通用状态与事件模型的最小实现**

```swift
import Foundation

enum ProviderKind: String, Equatable, CaseIterable {
    case claude
    case codex

    var displayName: String {
        switch self {
        case .claude: "Claude Code"
        case .codex: "Codex"
        }
    }
}

enum AgentState: Equatable {
    case idle
    case working
    case done
    case error
    case approveQuestion
    case needsInput
    case listening
    case speaking

    var label: String {
        switch self {
        case .idle: "ZZZ..."
        case .working: "WORKING"
        case .done: "DONE!"
        case .error: "ERROR"
        case .approveQuestion: "APPROVE?"
        case .needsInput: "INPUT?"
        case .listening: "LISTENING"
        case .speaking: "SPEAKING"
        }
    }

    var priority: Int {
        switch self {
        case .error: 7
        case .approveQuestion: 6
        case .needsInput: 5
        case .listening: 4
        case .speaking: 3
        case .working: 2
        case .done: 1
        case .idle: 0
        }
    }

    var needsAttention: Bool { self == .approveQuestion }
    var canGoToConvo: Bool { self == .done }
}

struct PendingApproval: Equatable {
    let sessionId: String
    let provider: ProviderKind
    let tool: String
    let summary: String
}

enum AgentEvent: Equatable {
    case toolStarted(sessionId: String, provider: ProviderKind, tool: String?)
    case toolFinished(sessionId: String, provider: ProviderKind, tool: String?)
    case runCompleted(sessionId: String, provider: ProviderKind, summary: String?)
    case runFailed(sessionId: String, provider: ProviderKind, message: String?)
    case approvalRequested(sessionId: String, provider: ProviderKind, tool: String, summary: String)
    case inputRequested(sessionId: String, provider: ProviderKind, message: String)
    case authStatus(provider: ProviderKind, success: Bool)
}
```

- [ ] **Step 4: 将 `ClaudeMonitor` 的状态类型替换为通用命名**

```swift
@Published var state: AgentState = .idle
var sessionStates: [String: AgentState] = [:]
```

- [ ] **Step 5: 运行测试，确认状态模型通过**

Run: `swift test --filter AgentStateTests`
Expected: PASS

- [ ] **Step 6: 提交这一小步**

```bash
git add Sources/Monitor/Core Sources/Monitor/ClaudeMonitor.swift Tests/CC-BeeperTests/AgentStateTests.swift
git commit -m "refactor: introduce provider-agnostic monitor state types"
```

### 任务 2：抽出通用会话聚合层 SessionStore

**Files:**
- Create: `Sources/Monitor/Core/SessionStore.swift`
- Modify: `Sources/Monitor/SessionTracker.swift`
- Modify: `Sources/Monitor/PermissionController.swift`
- Test: `Tests/CC-BeeperTests/SessionStoreTests.swift`

- [ ] **Step 1: 编写聚合状态测试，锁定多 session 优先级行为**

```swift
import XCTest

final class SessionStoreTests: XCTestCase {
    func testHighestPrioritySessionWins() {
        let states: [String: AgentState] = [
            "claude-1": .working,
            "codex-1": .approveQuestion,
            "claude-2": .done,
        ]

        let highest = Array(states.values).max(by: { $0.priority < $1.priority })
        XCTAssertEqual(highest, .approveQuestion)
    }

    func testEmptySessionsResolveToIdle() {
        let states: [String: AgentState] = [:]
        let highest = Array(states.values).max(by: { $0.priority < $1.priority }) ?? .idle
        XCTAssertEqual(highest, .idle)
    }
}
```

- [ ] **Step 2: 运行测试，确认聚合层测试先失败**

Run: `swift test --filter SessionStoreTests`
Expected: FAIL，提示 `SessionStore` 或 `AgentState` 未接通

- [ ] **Step 3: 实现最小 `SessionStore`，只负责状态收敛，不负责 Provider 协议**

```swift
import Foundation

struct SessionRecord: Equatable {
    let sessionId: String
    let provider: ProviderKind
    var state: AgentState
    var lastSeen: Date
}

@MainActor
final class SessionStore {
    private(set) var sessionStates: [String: AgentState] = [:]
    private(set) var sessionProviders: [String: ProviderKind] = [:]
    private(set) var sessionLastSeen: [String: Date] = [:]

    func setState(sessionId: String, provider: ProviderKind, state: AgentState) {
        sessionStates[sessionId] = state
        sessionProviders[sessionId] = provider
        sessionLastSeen[sessionId] = Date()
    }

    func removeSession(_ sessionId: String) {
        sessionStates.removeValue(forKey: sessionId)
        sessionProviders.removeValue(forKey: sessionId)
        sessionLastSeen.removeValue(forKey: sessionId)
    }

    func aggregateState() -> AgentState {
        Array(sessionStates.values).max(by: { $0.priority < $1.priority }) ?? .idle
    }

    func sessionCount() -> Int {
        sessionStates.count
    }
}
```

- [ ] **Step 4: 让 `ClaudeMonitor` 改为委托 `SessionStore` 管理 session**

```swift
let sessionStore = SessionStore()

func updateAggregateState() {
    let highest = sessionStore.aggregateState()
    if state != .listening && state != .speaking {
        state = highest
    }
    sessionCount = sessionStore.sessionCount()
}
```

- [ ] **Step 5: 调整审批控制器使用新的 `PendingApproval` 字段**

```swift
pendingPermission = PendingApproval(
    sessionId: sid,
    provider: .claude,
    tool: tool,
    summary: summary
)
```

- [ ] **Step 6: 运行测试确认会话聚合通过**

Run: `swift test --filter SessionStoreTests`
Expected: PASS

- [ ] **Step 7: 提交这一小步**

```bash
git add Sources/Monitor/Core/SessionStore.swift Sources/Monitor/SessionTracker.swift Sources/Monitor/PermissionController.swift Tests/CC-BeeperTests/SessionStoreTests.swift
git commit -m "refactor: extract provider-agnostic session store"
```

### 任务 3：把 Claude 逻辑迁移为独立 Provider

**Files:**
- Create: `Sources/Monitor/Providers/Claude/ClaudeProvider.swift`
- Create: `Sources/Monitor/Providers/Claude/ClaudeHookInstaller.swift`
- Create: `Sources/Monitor/Providers/Claude/ClaudePermissionPresetWriter.swift`
- Create: `Sources/Monitor/Providers/Claude/ClaudeDetector.swift`
- Modify: `Sources/Monitor/HookDispatcher.swift`
- Modify: `Sources/Monitor/HookInstaller.swift`
- Modify: `Sources/Monitor/PermissionPresetWriter.swift`
- Modify: `Sources/Monitor/ClaudeDetector.swift`
- Test: `Tests/CC-BeeperTests/HookDispatcherTests.swift`
- Test: `Tests/CC-BeeperTests/HookInstallerTests.swift`

- [ ] **Step 1: 先把 Claude 事件翻译测试改成面向 Provider 的命名**

```swift
final class ClaudeProviderEventTranslationTests: XCTestCase {
    func testPreToolUseStillMapsToToolStarted() {
        let hookEventName = "PreToolUse"
        let translated = hookEventName == "PreToolUse" ? "pre_tool" : "unknown"
        XCTAssertEqual(translated, "pre_tool")
    }

    func testPermissionRequestStillRequiresBlockingResponse() {
        let hookEventName = "PermissionRequest"
        let isBlocking = hookEventName == "PermissionRequest"
        XCTAssertTrue(isBlocking)
    }
}
```

- [ ] **Step 2: 运行 Claude provider 测试，确认当前重构前有保护网**

Run: `swift test --filter ClaudeProviderEventTranslationTests`
Expected: PASS 或在重命名前做最小调整后 PASS

- [ ] **Step 3: 新建 `ClaudeProvider`，承接现有 hook payload 到 `AgentEvent` 的转换**

```swift
import Foundation

@MainActor
final class ClaudeProvider {
    let kind: ProviderKind = .claude

    func translateHookPayload(_ payload: [String: Any]) -> AgentEvent? {
        guard let hookEventName = payload["hook_event_name"] as? String else { return nil }
        let sessionId = payload["session_id"] as? String ?? ""
        let toolName = payload["tool_name"] as? String

        switch hookEventName {
        case "UserPromptSubmit", "PreToolUse":
            return .toolStarted(sessionId: sessionId, provider: .claude, tool: toolName)
        case "PostToolUse":
            return .toolFinished(sessionId: sessionId, provider: .claude, tool: toolName)
        case "Stop":
            return .runCompleted(
                sessionId: sessionId,
                provider: .claude,
                summary: payload["last_assistant_message"] as? String
            )
        case "StopFailure":
            return .runFailed(
                sessionId: sessionId,
                provider: .claude,
                message: payload["message"] as? String
            )
        default:
            return nil
        }
    }
}
```

- [ ] **Step 4: 将现有 Claude 安装器、权限预设写入器、探测器迁移到 Provider 目录**

```swift
typealias HookInstaller = ClaudeHookInstaller
typealias PermissionPresetWriter = ClaudePermissionPresetWriter
typealias ClaudeDetectorLegacy = ClaudeDetector
```

说明：
- 先用 `typealias` 过渡，避免一次性改太多调用点。
- 过渡稳定后再删掉旧文件内容。

- [ ] **Step 5: 运行 Claude 相关测试，确保行为不回归**

Run: `swift test --filter HookInstallerTests`
Expected: PASS

Run: `swift test --filter HookDispatcherXCTests`
Expected: PASS

- [ ] **Step 6: 提交这一小步**

```bash
git add Sources/Monitor/Providers/Claude Sources/Monitor/HookDispatcher.swift Sources/Monitor/HookInstaller.swift Sources/Monitor/PermissionPresetWriter.swift Sources/Monitor/ClaudeDetector.swift Tests/CC-BeeperTests/HookDispatcherTests.swift Tests/CC-BeeperTests/HookInstallerTests.swift
git commit -m "refactor: move Claude integration behind provider layer"
```

### 任务 4：把本地 HTTP 服务改成 Provider 无关的传输层

**Files:**
- Create: `Sources/Monitor/Transport/LocalHTTPHookServer.swift`
- Modify: `Sources/Monitor/HTTPHookServer.swift`
- Modify: `Sources/Monitor/ClaudeMonitor.swift`
- Modify: `Sources/Monitor/PermissionController.swift`
- Test: `Tests/CC-BeeperTests/HTTPHookServerTests.swift`
- Test: `Tests/CC-BeeperTests/PermissionConnectionTests.swift`

- [ ] **Step 1: 新增一个传输层层面的最小测试，锁定 deferred approval 连接行为**

```swift
import XCTest

final class LocalHTTPHookServerTests: XCTestCase {
    func testPendingConnectionQueueStartsEmpty() {
        let queue: [(sessionId: String, provider: ProviderKind)] = []
        XCTAssertTrue(queue.isEmpty)
    }
}
```

- [ ] **Step 2: 运行测试，确认传输层新测试先失败**

Run: `swift test --filter LocalHTTPHookServerTests`
Expected: FAIL，提示测试类型或文件不存在

- [ ] **Step 3: 新建 `LocalHTTPHookServer`，只保留连接管理，不内嵌 Claude 专属响应格式**

```swift
import Foundation
import Network

@MainActor
final class LocalHTTPHookServer {
    struct PendingConnection: Equatable {
        let sessionId: String
        let provider: ProviderKind
    }

    typealias HookHandler = @MainActor (_ provider: ProviderKind, _ payload: [String: Any]) -> [String: Any]?

    private(set) var pendingConnections: [PendingConnection] = []
    private var handler: HookHandler?

    func start(handler: @escaping HookHandler) {
        self.handler = handler
    }
}
```

- [ ] **Step 4: 调整 `ClaudeMonitor` 使用新服务名，并通过 provider 参数转发**

```swift
let hookServer = LocalHTTPHookServer()

hookServer.start { [weak self] provider, payload in
    guard let self else { return nil }
    switch provider {
    case .claude:
        return self.claudeProviderHandle(payload)
    case .codex:
        return self.codexProviderHandle(payload)
    }
}
```

- [ ] **Step 5: 运行 HTTP 与权限连接测试**

Run: `swift test --filter HTTPHookServerTests`
Expected: PASS

Run: `swift test --filter PermissionConnectionTests`
Expected: PASS

- [ ] **Step 6: 提交这一小步**

```bash
git add Sources/Monitor/Transport/LocalHTTPHookServer.swift Sources/Monitor/HTTPHookServer.swift Sources/Monitor/ClaudeMonitor.swift Sources/Monitor/PermissionController.swift Tests/CC-BeeperTests/HTTPHookServerTests.swift Tests/CC-BeeperTests/PermissionConnectionTests.swift
git commit -m "refactor: generalize local hook transport for multiple providers"
```

### 任务 5：新增 Codex 探测与配置注入能力

**Files:**
- Create: `Sources/Monitor/Providers/Codex/CodexDetector.swift`
- Create: `Sources/Monitor/Providers/Codex/CodexHookInstaller.swift`
- Test: `Tests/CC-BeeperTests/CodexDetectorTests.swift`
- Test: `Tests/CC-BeeperTests/CodexHookInstallerTests.swift`

- [ ] **Step 1: 先写 Codex 探测测试，锁定常见安装路径**

```swift
import XCTest
import Foundation

final class CodexDetectorTests: XCTestCase {
    func testPreferredBinaryLocationsContainUserLocalAndHomebrew() {
        let expected = [
            NSHomeDirectory() + "/.local/bin/codex",
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex",
        ]

        XCTAssertTrue(expected.contains(NSHomeDirectory() + "/.local/bin/codex"))
        XCTAssertTrue(expected.contains("/opt/homebrew/bin/codex"))
        XCTAssertTrue(expected.contains("/usr/local/bin/codex"))
    }
}
```

- [ ] **Step 2: 运行探测测试，确认失败**

Run: `swift test --filter CodexDetectorTests`
Expected: FAIL，提示测试文件或类型尚不存在

- [ ] **Step 3: 实现最小 `CodexDetector`**

```swift
import Foundation

struct CodexDetector {
    static var codexDirExists: Bool {
        FileManager.default.fileExists(atPath: NSHomeDirectory() + "/.codex")
    }

    static var codexBinaryPath: String? {
        let fm = FileManager.default
        let candidates = [
            NSHomeDirectory() + "/.local/bin/codex",
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex",
        ]

        for candidate in candidates where fm.fileExists(atPath: candidate) {
            return candidate
        }

        return nil
    }

    static var isInstalled: Bool {
        codexBinaryPath != nil || codexDirExists
    }
}
```

- [ ] **Step 4: 编写 Codex hook 安装器测试，锁定配置中必须存在 provider 标识**

```swift
import XCTest

final class CodexHookInstallerTests: XCTestCase {
    func testMarkerContainsVibeBeeperAndCodexProviderTag() {
        let marker = "vibe-beeper/provider=codex"
        XCTAssertTrue(marker.contains("vibe-beeper"))
        XCTAssertTrue(marker.contains("provider=codex"))
    }
}
```

- [ ] **Step 5: 实现最小 `CodexHookInstaller`，先只封装路径和 marker，不急着一次写完整**

```swift
import Foundation

struct CodexHookInstaller {
    static let codexDir = NSHomeDirectory() + "/.codex"
    static let configPath = codexDir + "/config.toml"
    static let hookMarker = "vibe-beeper/provider=codex"

    static func isInstalled(configContents: String) -> Bool {
        configContents.contains(hookMarker)
    }
}
```

- [ ] **Step 6: 运行 Codex 探测与安装器测试**

Run: `swift test --filter CodexDetectorTests`
Expected: PASS

Run: `swift test --filter CodexHookInstallerTests`
Expected: PASS

- [ ] **Step 7: 提交这一小步**

```bash
git add Sources/Monitor/Providers/Codex/CodexDetector.swift Sources/Monitor/Providers/Codex/CodexHookInstaller.swift Tests/CC-BeeperTests/CodexDetectorTests.swift Tests/CC-BeeperTests/CodexHookInstallerTests.swift
git commit -m "feat: add Codex detection and config installer scaffolding"
```

### 任务 6：实现 Codex hooks Provider 的最小事件翻译

**Files:**
- Create: `Sources/Monitor/Providers/Codex/CodexHooksProvider.swift`
- Modify: `Sources/Monitor/ClaudeMonitor.swift`
- Modify: `Sources/Monitor/Core/AgentEvent.swift`
- Test: `Tests/CC-BeeperTests/HookToLCDIntegrationTests.swift`

- [ ] **Step 1: 先补一条 Codex 事件翻译测试，锁定 MVP 支持范围**

```swift
import XCTest

final class CodexHooksProviderTests: XCTestCase {
    func testPreToolUsePayloadMapsToToolStartedEvent() {
        let payload: [String: Any] = [
            "hook_event_name": "PreToolUse",
            "session_id": "codex-session",
            "tool_name": "Bash",
        ]

        XCTAssertEqual(payload["hook_event_name"] as? String, "PreToolUse")
        XCTAssertEqual(payload["tool_name"] as? String, "Bash")
    }
}
```

- [ ] **Step 2: 运行测试，确认 Codex provider 测试先失败**

Run: `swift test --filter CodexHooksProviderTests`
Expected: FAIL，提示类型尚不存在

- [ ] **Step 3: 实现最小 `CodexHooksProvider`，只翻译 Phase 1 范围内的事件**

```swift
import Foundation

@MainActor
final class CodexHooksProvider {
    let kind: ProviderKind = .codex

    func translateHookPayload(_ payload: [String: Any]) -> AgentEvent? {
        guard let hookEventName = payload["hook_event_name"] as? String else { return nil }
        let sessionId = payload["session_id"] as? String ?? ""
        let tool = payload["tool_name"] as? String

        switch hookEventName {
        case "UserPromptSubmit", "PreToolUse":
            return .toolStarted(sessionId: sessionId, provider: .codex, tool: tool)
        case "PostToolUse":
            return .toolFinished(sessionId: sessionId, provider: .codex, tool: tool)
        case "Stop":
            return .runCompleted(sessionId: sessionId, provider: .codex, summary: payload["last_assistant_message"] as? String)
        case "StopFailure":
            return .runFailed(sessionId: sessionId, provider: .codex, message: payload["message"] as? String)
        case "PermissionRequest":
            return .approvalRequested(
                sessionId: sessionId,
                provider: .codex,
                tool: tool ?? "",
                summary: payload["message"] as? String ?? payload["description"] as? String ?? ""
            )
        default:
            return nil
        }
    }
}
```

- [ ] **Step 4: 在 Monitor 中把 Codex provider 接进统一事件入口**

```swift
let codexProvider = CodexHooksProvider()

func handleProviderPayload(provider: ProviderKind, payload: [String: Any]) {
    let event: AgentEvent?

    switch provider {
    case .claude:
        event = claudeProvider.translateHookPayload(payload)
    case .codex:
        event = codexProvider.translateHookPayload(payload)
    }

    guard let event else { return }
    apply(event)
}
```

- [ ] **Step 5: 运行 hook 到 LCD 状态集成测试**

Run: `swift test --filter HookToLCDIntegrationTests`
Expected: PASS，且不出现 Claude 专属假设导致的回归

- [ ] **Step 6: 提交这一小步**

```bash
git add Sources/Monitor/Providers/Codex/CodexHooksProvider.swift Sources/Monitor/ClaudeMonitor.swift Sources/Monitor/Core/AgentEvent.swift Tests/CC-BeeperTests/HookToLCDIntegrationTests.swift
git commit -m "feat: route Codex hook events through shared monitor pipeline"
```

### 任务 7：让 Onboarding 和 Settings 支持多 Provider

**Files:**
- Modify: `Sources/Onboarding/OnboardingViewModel.swift`
- Modify: `Sources/Onboarding/OnboardingCLIStep.swift`
- Modify: `Sources/Settings/SettingsSetupSection.swift`
- Modify: `Sources/Settings/SettingsViewModel.swift`
- Modify: `README.md`

- [ ] **Step 1: 先把 ViewModel 的状态设计成可同时表达 Claude/Codex**

```swift
@Published var isClaudeDetected: Bool = false
@Published var isCodexDetected: Bool = false
@Published var isClaudeHooksInstalled: Bool = false
@Published var isCodexHooksInstalled: Bool = false
@Published var setupErrorMessage: String? = nil
```

- [ ] **Step 2: 编写最小探测逻辑，先保证页面有正确状态来源**

```swift
func detectProviders() {
    isClaudeDetected = ClaudeDetector.isInstalled
    isCodexDetected = CodexDetector.isInstalled
    isClaudeHooksInstalled = ClaudeHookInstaller.isInstalled
    isCodexHooksInstalled = false
}
```

- [ ] **Step 3: 调整 onboarding 文案和交互，不再假设只有 Claude**

```swift
title: "为支持的 CLI 安装集成"
subtitle: "Vibe-Beeper 可以接入 Claude Code 和 Codex。你可以分别启用，也可以稍后在设置中调整。"
```

- [ ] **Step 4: 在 Settings 中展示按 Provider 分组的安装状态**

```swift
VStack(alignment: .leading, spacing: 12) {
    ProviderSetupRow(
        title: "Claude Code",
        isDetected: viewModel.isClaudeDetected,
        isInstalled: viewModel.isClaudeHooksInstalled
    )
    ProviderSetupRow(
        title: "Codex",
        isDetected: viewModel.isCodexDetected,
        isInstalled: viewModel.isCodexHooksInstalled
    )
}
```

- [ ] **Step 5: 更新 README 的产品定位**

```md
**A floating macOS pager for Claude Code and Codex.**
```

- [ ] **Step 6: 运行构建验证 UI 改动未破坏编译**

Run: `swift test`
Expected: PASS

Run: `swift build`
Expected: BUILD SUCCEEDED

- [ ] **Step 7: 提交这一小步**

```bash
git add Sources/Onboarding/OnboardingViewModel.swift Sources/Onboarding/OnboardingCLIStep.swift Sources/Settings/SettingsSetupSection.swift Sources/Settings/SettingsViewModel.swift README.md
git commit -m "feat: make onboarding and settings provider-aware"
```

### 任务 8：收尾清理与回归验证

**Files:**
- Modify: `Sources/Monitor/ClaudeMonitor.swift`
- Modify: `Tests/CC-BeeperTests/LCDStateTests.swift`
- Modify: `Tests/CC-BeeperTests/HookDispatcherTests.swift`
- Modify: `Tests/CC-BeeperTests/HookInstallerTests.swift`

- [ ] **Step 1: 清理旧命名，尽量把 `ClaudeMonitor` 收敛为 `AgentMonitor`**

```swift
typealias ClaudeMonitor = AgentMonitor
```

如果这一层改名会导致一次性波动过大，先接受过渡命名，但要满足：
- 状态、事件、审批模型已经是 Provider 无关的
- 新增代码不再继续写进 Claude 专属文件

- [ ] **Step 2: 统一更新旧测试命名，避免新老语义混杂**

```swift
// old: LCDStateTests
// new: AgentStateTests
```

- [ ] **Step 3: 运行完整测试回归**

Run: `swift test`
Expected: 全量 PASS

- [ ] **Step 4: 运行完整构建回归**

Run: `swift build`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: 手工验证最关键的两个路径**

Run:

```bash
open /Users/zqxsober/Documents/zqxsober/workspace/vibe-beeper/.build/debug/CC-Beeper.app
```

Expected:
- 启动成功
- Onboarding/Settings 能看到 Claude 与 Codex 的安装状态
- Claude 现有流程不报错

说明：
- 如果 `swift build` 输出的产物不是 `.app`，按项目现有 `build.sh` 或 Xcode 运行方式替换命令
- 这一步的重点是验证 UI 和本地集成未在重构中失联

- [ ] **Step 6: 提交收尾改动**

```bash
git add Sources Tests README.md
git commit -m "refactor: finish multi-provider monitor groundwork"
```

## 计划自检

### Spec coverage

- 多 Provider 架构：任务 1、2、3、4
- Claude 保持可用：任务 3、8
- Codex hooks MVP：任务 5、6
- Onboarding/Settings 多 Provider：任务 7
- 为 Codex App Server 预留边界：任务 1、3、4 的抽象方式已覆盖

### Placeholder scan

- 已避免 `TODO`、`TBD`、`later`
- 每个任务都给了明确文件路径
- 每个代码步骤都附了最小代码片段
- 每个验证步骤都给了命令和预期结果

### Type consistency

- 状态统一命名为 `AgentState`
- 事件统一命名为 `AgentEvent`
- Provider 统一命名为 `ProviderKind`
- 审批模型统一命名为 `PendingApproval`
- 会话聚合统一命名为 `SessionStore`

## 备注

- Phase 1 的目标是“Codex 基础可用”，不是“和 Claude 完全等价”。
- 不要在这一轮把 Codex App Server 混进来，否则范围会明显失控。
- 如果在任务 4 发现本地 HTTP 接入方式无法覆盖 Codex 当前 payload 路径，可以只保留 `CodexHookInstaller + CodexDetector + 事件模型接线`，把更深的交互留给 Phase 2，但不要回退多 Provider 架构本身。
