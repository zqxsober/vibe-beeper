# Vibe-Beeper Multi-Provider Support Design

## 1. Summary

Evolve `vibe-beeper` from a Claude Code-specific desktop companion into a multi-provider macOS pager that supports both Claude Code and Codex.

The key design decision is to preserve the current UI, voice, hotkey, and window-management layers as much as possible while extracting provider-specific monitoring, hook installation, approval handling, and CLI detection into isolated provider adapters.

This design intentionally splits delivery into two phases:

1. Phase 1: introduce a multi-provider architecture and add Codex support through hooks/notify-style integration.
2. Phase 2: add a dedicated Codex App Server provider for deeper, more reliable event and approval handling.

## 2. Goals

- Keep existing Claude Code behavior working without regressions.
- Add Codex as a first-class supported provider.
- Make the UI and session state model provider-agnostic.
- Isolate provider-specific configuration and protocol logic.
- Avoid a large rewrite of the current app shell, widget, voice, and settings layers.

## 3. Non-Goals

- Do not remove Claude-specific support in Phase 1.
- Do not implement full Codex App Server support in the first delivery.
- Do not redesign the widget visuals, voice UX, or hotkey model unless required by the provider abstraction.
- Do not add support for more providers beyond Claude Code and Codex in this change.

## 4. Current State

The repository already has a useful separation between presentation and monitoring, but the monitoring layer is strongly coupled to Claude Code:

- `Sources/Monitor/HookInstaller.swift` writes to `~/.claude/settings.json`
- `Sources/Monitor/HookDispatcher.swift` translates Claude hook payloads into internal synthetic events
- `Sources/Monitor/HTTPHookServer.swift` exposes a local HTTP endpoint for hook delivery and permission responses
- `Sources/Monitor/ClaudeMonitor.swift` owns app-facing state and Claude-specific behavior
- `Sources/Monitor/ClaudeDetector.swift` probes Claude installation locations
- `Sources/Monitor/PermissionPresetWriter.swift` persists Claude permission presets
- `Sources/Onboarding/OnboardingCLIStep.swift` assumes Claude is the only supported CLI

The reusable part of the app is substantial:

- Widget and menu bar UI
- Voice recording and TTS
- Hotkeys
- Session prioritization logic
- Local alerting behavior

## 5. Constraints

- Existing Claude Code behavior must continue to work during and after refactoring.
- Codex hooks currently have feature boundaries, so Phase 1 Codex support must be explicitly scoped as “basic but usable”, not “feature-equivalent to Claude”.
- Approval payloads and config paths are provider-specific and must not be hard-coded in shared abstractions.
- The repo should remain understandable and easy to extend after the refactor.

## 6. Options Considered

### Option A: Extend the current Claude-specific monitor with conditional branches

Add Codex support directly inside `ClaudeMonitor`, `HookInstaller`, and related files.

Pros:

- Fastest initial implementation.
- Minimal short-term file movement.

Cons:

- Tightens coupling between unrelated provider protocols.
- Makes approval handling and config management harder to reason about.
- Creates a poor base for Codex App Server support later.

Decision:

- Rejected. Good for a throwaway spike, not for a maintainable fork.

### Option B: Introduce provider adapters and support Codex via hooks first

Extract provider-agnostic state and monitoring interfaces, keep Claude support via its current hook model, and add a Codex hooks-based provider as the first Codex implementation.

Pros:

- Good balance between delivery speed and code quality.
- Preserves most of the app.
- Provides a clean place to add Codex App Server later.

Cons:

- Phase 1 Codex support will still inherit hooks coverage limitations.

Decision:

- Accepted for Phase 1.

### Option C: Build full multi-provider architecture and Codex App Server immediately

Implement provider abstraction and Codex App Server integration in the first wave.

Pros:

- Best long-term technical direction.
- Stronger Codex approval and event model.

Cons:

- Larger initial scope.
- More moving parts while refactoring the current Claude implementation.

Decision:

- Deferred to Phase 2.

## 7. Recommended Architecture

### 7.1 Provider-Agnostic Core

Introduce a shared monitoring core that owns:

- aggregate app state
- session lifecycle tracking
- provider selection
- pending approval presentation
- shared hotkey and alert behavior

Recommended core types:

- `ProviderKind`
- `AgentState`
- `AgentEvent`
- `AgentSession`
- `PendingApproval`
- `SessionStore`
- `AgentMonitor`

### 7.2 Provider Adapters

Each provider is responsible for:

- installation detection
- hook/config setup
- translating provider-native events into shared `AgentEvent`
- handling approval responses back to the provider

Recommended provider protocol:

```swift
protocol ProviderAdapter: AnyObject {
    var kind: ProviderKind { get }
    var displayName: String { get }
    func start()
    func stop()
    func installIntegration() throws
    func uninstallIntegration() throws
    func detectInstallation() -> Bool
    func respondToApproval(sessionId: String, allow: Bool)
}
```

Phase 1 adapters:

- `ClaudeProvider`
- `CodexHooksProvider`

Phase 2 adapter:

- `CodexAppServerProvider`

### 7.3 Transport Layer

Keep the existing local HTTP server concept, but stop treating it as Claude-specific.

Recommended rename:

- `HTTPHookServer.swift` -> `LocalHTTPHookServer.swift`

The shared transport layer should:

- accept provider-tagged hook payloads
- support deferred approval responses
- avoid embedding provider-specific response bodies in generic APIs

Provider-specific payload building should live in the provider adapter, not in the transport class.

## 8. Proposed Module Layout

```text
Sources/Monitor/Core
- AgentState.swift
- AgentEvent.swift
- SessionStore.swift
- PermissionModels.swift
- ProviderKind.swift

Sources/Monitor/Providers/Claude
- ClaudeProvider.swift
- ClaudeHookInstaller.swift
- ClaudePermissionPresetWriter.swift
- ClaudeDetector.swift

Sources/Monitor/Providers/Codex
- CodexHooksProvider.swift
- CodexHookInstaller.swift
- CodexConfigWriter.swift
- CodexDetector.swift

Sources/Monitor/Transport
- LocalHTTPHookServer.swift

Sources/Monitor
- AgentMonitor.swift
```

This structure keeps the current code recognizable while making provider boundaries explicit.

## 9. Shared Event Model

The UI and session store should consume a normalized event model instead of provider-native payloads.

Recommended event model:

```swift
enum AgentEvent {
    case sessionStarted(sessionId: String, provider: ProviderKind)
    case toolStarted(sessionId: String, provider: ProviderKind, tool: String?)
    case toolFinished(sessionId: String, provider: ProviderKind, tool: String?)
    case runCompleted(sessionId: String, provider: ProviderKind, summary: String?)
    case runFailed(sessionId: String, provider: ProviderKind, message: String?)
    case approvalRequested(sessionId: String, provider: ProviderKind, tool: String, summary: String)
    case inputRequested(sessionId: String, provider: ProviderKind, message: String)
    case authStatus(provider: ProviderKind, success: Bool)
}
```

Recommended aggregate visual state:

```swift
enum AgentState {
    case idle
    case working
    case done
    case error
    case approveQuestion
    case needsInput
    case listening
    case speaking
}
```

This preserves the current widget vocabulary while removing the provider name from the state model.

## 10. Provider Behavior

### 10.1 ClaudeProvider

Claude support should preserve the current behavior with minimal logic changes:

- continue using `~/.claude/settings.json`
- continue using the local HTTP hook server
- continue translating Claude hook payloads to shared events
- continue using existing preset semantics for approvals

The main refactor task is relocation and interface cleanup, not behavior change.

### 10.2 CodexHooksProvider

Phase 1 Codex support should:

- detect Codex installation
- install Codex integration through the official config entry points available today
- consume Codex hook or notify payloads
- map Codex events to shared `AgentEvent`
- support basic approval prompts when the available Codex hook surface provides them

Phase 1 boundaries:

- not all Codex tool activity may be visible through hooks
- approval semantics may be narrower than Claude’s current experience
- some advanced Codex capabilities should be deferred to the App Server provider

### 10.3 CodexAppServerProvider

Phase 2 should add a dedicated provider that:

- connects to the Codex App Server
- subscribes to streamed agent events
- handles approval flows through the official server protocol
- becomes the preferred Codex backend once stable

This provider should coexist with `CodexHooksProvider` until the app-server path is verified as stable enough to replace or supersede it.

## 11. UI and Onboarding Changes

### 11.1 UI Changes

UI changes should stay intentionally small in Phase 1:

- replace hard-coded “Claude” phrasing where it refers to the active provider
- add provider-aware labels where useful
- keep state visuals, menu layout, and voice interactions intact

### 11.2 Onboarding Changes

The current onboarding assumes Claude is the only target.

Phase 1 onboarding should:

- detect Claude and Codex independently
- let the user choose which integrations to enable
- show installation status per provider
- keep hook installation wording provider-specific

The onboarding should not require the user to understand internal architectural details.

## 12. Settings Changes

Settings should evolve from Claude-only setup to provider-aware setup:

- show detected providers
- expose install or reinstall actions per provider
- preserve Claude permission preset management
- leave room for Codex-specific settings without over-designing them in Phase 1

Important guardrail:

- do not force a shared permission model if the underlying providers differ materially

## 13. Implementation Phases

### Phase 1: Multi-Provider Refactor + Codex Hooks MVP

Scope:

- rename and generalize the monitor layer
- introduce shared event and state models
- isolate Claude-specific code into a provider module
- add Codex detection and configuration support
- add Codex hook or notify event translation
- update onboarding and settings to handle more than one provider

Success criteria:

- Claude still works end to end
- Codex can trigger visible state changes for its supported events
- approval prompts work where Codex officially exposes them
- UI no longer assumes Claude is the only provider

### Phase 2: Codex App Server Integration

Scope:

- add a dedicated Codex App Server adapter
- support richer event streams and approval workflows
- decide whether hooks remain a fallback or become secondary

Success criteria:

- Codex support becomes more complete and more reliable than the hooks-based MVP
- approval handling is cleaner and less provider-fragile

## 14. Risks

### 14.1 Event Coverage Risk

Codex hooks may not expose the full activity surface needed for a Claude-equivalent experience in Phase 1.

Mitigation:

- explicitly scope the Codex hooks integration as an MVP
- design the provider boundary so App Server can replace or augment it later

### 14.2 Approval Protocol Risk

The current approval transport is shaped around Claude hook responses.

Mitigation:

- move approval response shaping into providers
- keep the transport responsible only for connection management

### 14.3 Regression Risk for Claude

Refactoring the current Claude monitor into a provider could easily introduce regressions.

Mitigation:

- preserve behavior while moving code
- add focused tests around event translation, session aggregation, and approval response flow

### 14.4 Configuration Risk

Provider-specific config files and installation locations differ.

Mitigation:

- never share file path constants across providers
- encapsulate config writes in provider-owned components

## 15. Testing Strategy

Add or update tests around:

- Claude event translation
- Codex event translation
- aggregate session priority resolution
- pending approval queue behavior
- provider detection
- provider-specific config writing
- onboarding state for mixed provider availability

Phase 1 does not require full integration test coverage for Codex App Server because that work is deferred.

## 16. Recommended First Implementation Slice

Start with the smallest structural change that unlocks the rest:

1. Introduce shared state and event types.
2. Rename `ClaudeMonitor` responsibilities into a provider-agnostic `AgentMonitor`.
3. Wrap the current Claude-specific behavior inside `ClaudeProvider`.
4. Make onboarding and settings provider-aware without changing their overall UX too much.
5. Add `CodexDetector` and `CodexHooksProvider`.

This order reduces the chance of mixing Codex-specific logic into the current Claude code before the architecture is ready.

## 17. Final Decision

Proceed with a two-phase multi-provider design:

- Phase 1: provider abstraction plus Codex hooks-based support
- Phase 2: Codex App Server integration

This delivers a practical path to Codex support without sacrificing maintainability or destabilizing the current app more than necessary.
