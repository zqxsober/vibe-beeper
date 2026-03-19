# Structure

## Directory Layout

```
Claumagotchi/
├── Sources/                    # Swift source files (SPM executable target)
│   ├── ClaumagotchiApp.swift   # @main App, MenuBarExtra, AppDelegate, EggIcon, WindowConfigurator
│   ├── ClaudeMonitor.swift     # State machine, file watcher, IPC, permission handling
│   ├── ContentView.swift       # Tamagotchi shell UI, action buttons, pixel title, noise texture
│   ├── ScreenView.swift        # LCD screen, pixel character sprites, status icons
│   └── ThemeManager.swift      # 9 color themes, dark mode, ShellTheme definition
├── hooks/
│   └── claumagotchi-hook.py    # Claude Code hook (Python) — event forwarding + permissions
├── Package.swift               # Swift Package Manager manifest (macOS 14+, Swift 5.10)
├── Makefile                    # build, install, uninstall, dmg, update, autoupdate targets
├── build.sh                    # Compiles Swift package → .app bundle with Info.plist + icon
├── create-dmg.sh               # Creates distributable DMG
├── update.sh                   # Git pull + rebuild + reinstall
├── setup.py                    # Installs hook into ~/.claude/settings.json
├── uninstall.py                # Removes hooks and IPC directory
├── com.claumagotchi.autoupdate.plist  # launchd plist for auto-update every 6 hours
├── icon.png                    # App icon source
├── screenshot.png              # README screenshot
├── LICENSE                     # MIT license
├── README.md                   # Project documentation
└── Claumagotchi.app/           # Pre-built app bundle (committed)
    └── Contents/
        ├── MacOS/Claumagotchi  # Compiled binary
        ├── Resources/AppIcon.icns
        └── Info.plist
```

## Key Locations

| What | Where |
|---|---|
| Swift sources | `Sources/` (5 files, ~1200 LOC total) |
| Hook script | `hooks/claumagotchi-hook.py` (~295 lines) |
| IPC directory (runtime) | `~/.claude/claumagotchi/` |
| Installed hook | `~/.claude/hooks/claumagotchi-hook.py` |
| Hook settings | `~/.claude/settings.json` (hooks section) |
| App path config | `~/.claude/hooks/claumagotchi-app-path` |
| PID file | `~/.claude/claumagotchi/claumagotchi.pid` |
| LaunchAgent | `~/Library/LaunchAgents/com.claumagotchi.autoupdate.plist` |

## Naming Conventions
- **Files**: PascalCase for Swift (`ClaudeMonitor.swift`), kebab-case for scripts (`claumagotchi-hook.py`)
- **Types**: PascalCase (`ClaudeState`, `ShellTheme`, `PendingPermission`)
- **Functions/Properties**: camelCase (`processEvent`, `shellColors`, `autoAccept`)
- **Constants**: camelCase in Swift, UPPER_SNAKE in Python (`PERMISSION_TIMEOUT`, `IPC_DIR`)
- **Sprites**: camelCase with state + frame number (`thinking1`, `alert2`, `yolo1`)

## File Responsibilities

| File | LOC | Role |
|---|---|---|
| `ClaumagotchiApp.swift` | ~238 | App lifecycle, menu bar, window config, egg icon, PID management |
| `ClaudeMonitor.swift` | ~297 | All state logic, file watching, IPC read/write, sound, timers |
| `ContentView.swift` | ~441 | Visual shell (egg body, buttons, pixel title, noise texture, Color hex extension) |
| `ScreenView.swift` | ~313 | LCD screen, sprites (10 frames across 5 states), grid overlay |
| `ThemeManager.swift` | ~115 | 9 themes, dark mode toggle, computed color properties |
| `claumagotchi-hook.py` | ~294 | Event mapping, permission flow, session tracking, app auto-launch |
| `setup.py` | ~98 | Hook installation into Claude Code settings |
