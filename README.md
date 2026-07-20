# DutiUI

A macOS menu bar utility that lets you **lock file extensions to specific applications** and automatically restores them when other apps try to take over.

> **Example**: You want `.md` files to always open with Obsidian, `.pdf` with Preview, and `.json` with VS Code. DutiUI monitors these associations and restores them if any app changes them.

![](screenshots/04_main_with_data_real.png)

## Why DutiUI?

macOS lets apps register themselves as default handlers for file types — often without asking. An app update might silently claim `.pdf` or `.txt`. DutiUI solves this by:

- Letting you **choose which extensions to protect** (not all system types)
- **Periodically checking** if your preferred defaults have changed
- **Automatically restoring** them when they do
- Keeping a **history** of every change and recovery

## Features

- 🛡 **Lock file extensions** to specific apps
- 🔄 **Auto-restore** changed associations (configurable interval)
- 📋 **Built-in catalog** of 60+ common file types with Chinese and English names
- 📊 **Change history** — see what changed and when it was restored
- 🚀 **Launch at login** with no Dock icon (menu bar only)
- 🌐 **Bilingual UI** — Simplified Chinese and English

## Requirements

- macOS 14 (Sonoma) or later
- [duti](https://github.com/moretension/duti) — a lightweight command-line tool to manage default apps on macOS

### Installing duti

```bash
brew install duti
```

DutiUI detects missing dependencies on launch and provides step-by-step installation instructions.

## Quick Start

### Download & Run

```bash
git clone https://github.com/ygnstudio/DutiUI.git
cd DutiUI
./build_app.sh
open DutiUI.app
```

Or open the project in Xcode and press `⌘R`.

### Usage

1. Click the **shield icon** in the menu bar to open DutiUI
2. Click **Add File Type** to search for extensions you want to manage
3. Select a default app for each extension
4. Toggle **Lock** to enable automatic protection
5. The app runs in the background — close the window, protection continues

| Action | Behavior |
|--------|----------|
| Left-click menu bar icon | Open / focus main window |
| Right-click menu bar icon | Open or Quit |
| Close main window | App keeps running (protection active) |
| Quit from menu | App fully exits (protection stops) |

## Project Structure

```
Sources/DutiUI/
├── DutiUIApp.swift              # App entry point
├── AppState.swift               # Global state management
├── Models/                      # Data models
├── Services/
│   ├── AssociationService.swift # UTI resolution + app management
│   ├── ProtectionService.swift  # Timer-based monitoring + auto-restore
│   ├── ExtensionCatalog.swift   # Built-in file type database
│   ├── CommandRunner.swift      # Safe process execution
│   ├── DutiDetector.swift       # Dependency detection
│   └── PersistenceController.swift # Local JSON storage
├── Views/                       # SwiftUI views
├── Utilities/                   # Helpers
└── Resources/                   # JSON catalog + localizations
```

## How It Works

DutiUI uses macOS Launch Services API to **query** default app associations and the [duti](https://github.com/moretention/duti) command-line tool to **write** them (macOS doesn't expose a public write API).

```
File extension → UTI → Default App (read via Launch Services)
                     → Set App (write via duti)
                     → Verify (re-read to confirm)
```

The "lock" is **detection-based**, not a system-level block. When another app changes a locked extension, DutiUI detects it on the next check cycle (default 10s) and restores it automatically.

## Building

```bash
# Command line
swift build
swift run

# Or use Xcode
open Package.swift
```

## License

MIT — see [LICENSE](LICENSE)
