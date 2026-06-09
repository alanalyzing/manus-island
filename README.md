# Manus Island

A native macOS Dynamic Island-style floating widget for monitoring and interacting with [Manus AI](https://manus.im) tasks in real-time.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift 5](https://img.shields.io/badge/Swift-5-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Dynamic Island UI** — Floating pill that expands to show active tasks, credits, and tool usage
- **Real-time task monitoring** — Polls the Manus API for task status, progress, and plan steps
- **Credits tracking** — Per-task and aggregate credit consumption from the `usage.list` endpoint
- **Tool usage analytics** — See which tools are being used across tasks with success rate indicators
- **Quick actions** — Send messages, stop tasks, confirm actions directly from the island
- **Task creation** — Create new tasks via text input or voice (Whisper transcription)
- **Website status** — Monitor published websites from tasks
- **Drag & drop** — Drop files onto the island to create tasks with file context
- **Spotlight integration** — Completed tasks are indexed for macOS Spotlight search
- **Webhook support** — Local webhook server for instant task status updates
- **Focus mode** — Auto-hide when no tasks need attention
- **Keyboard shortcut** — Cmd+Shift+M to toggle the island

## Requirements

- macOS 14.0+ (Sonoma or later)
- Apple Silicon (arm64)
- Xcode Command Line Tools (`xcode-select --install`)
- A [Manus API key](https://manus.im/settings)

## Build

### DMG (Recommended)

1. Download the latest `Manus-Island.dmg` from [Releases](../../releases)
2. Open the DMG and drag **Manus Island** to your Applications folder
3. Launch from Applications or Spotlight

### Build from Source

```bash
git clone https://github.com/alanalyzing/manus-island.git
cd manus-island
bash build.sh
```

The compiled app will be at `build/Manus Island.app`.

## Run

```bash
open "build/Manus Island.app"
```

On first launch, click the menu bar icon and enter your Manus API key in Settings.

## Configuration

All settings are stored in macOS UserDefaults (no config files). Configure via the Settings panel:

- **Manus API Key** — Required. Get yours from [manus.im/settings](https://manus.im/settings)
- **OpenAI API Key** — Optional. Required only for voice input (Whisper transcription)
- **Polling Interval** — How often to check for task updates (default: 5s)
- **Focus Mode** — Auto-hide island when no active tasks
- **Launch at Login** — Start automatically on login
- **Webhook** — Optional local webhook server for instant updates

## Architecture

```
ManusIsland/
├── main.swift                 # App entry point
├── AppDelegate.swift          # Menu bar, hotkey, lifecycle
├── IslandWindowController.swift  # Floating panel management
├── IslandView.swift           # SwiftUI Dynamic Island UI
├── ManusAPIClient.swift       # Manus API v2 client (all endpoints)
├── TaskStore.swift            # State management, polling, notifications
├── SettingsView.swift         # Settings panel + menu bar popover
├── ScreenTimeTracker.swift    # Manus app usage tracking
├── VoiceInputManager.swift    # Microphone + Whisper transcription
└── Resources/
    ├── Info.plist
    ├── AppIcon.icns
    └── menubar_icon*.png
```

## API Endpoints Used

| Endpoint | Purpose |
|----------|---------|
| `task.list` | List all tasks with status |
| `task.detail` | Get task activity, plan steps, tool stats |
| `task.create` | Create new tasks |
| `task.stop` | Stop running tasks |
| `task.sendMessage` | Send messages to tasks |
| `usage.list` | Per-task credit consumption |
| `usage.teamStatistic` | Daily credit statistics |
| `website.status` | Website publish status |
| `website.listCheckpoints` | Website deployment history |
| `browser.onlineList` | Connected browser clients |
| `agent.list` | Custom agents |
| `project.list` | Projects |
| `connector.list` | Connected apps |
| `skill.list` | Available skills |

## Security

- **No hardcoded API keys** — All credentials are entered at runtime and stored in macOS UserDefaults
- **No network calls without user consent** — API calls only happen after the user enters their key
- **No telemetry or analytics** — The app communicates only with `api.manus.im` and optionally `api.openai.com`
- **Safe for public repositories** — Audited for secrets, tokens, and personal data

## License

MIT
