# DutiUI

A macOS menu bar app for managing and locking default application associations for file extensions.

DutiUI lets you select the file extensions you care about (like `.md`, `.pdf`, `.json`) and lock their default applications. When another app tries to take over a locked file type, DutiUI automatically restores your preferred association.

## Features

- **Manage default apps** for specific file extensions
- **Lock associations** to prevent other apps from changing them
- **Auto-restore** when a locked association is changed
- **Recent changes history** to track what happened
- **Launch at login** for continuous protection
- **Runs in menu bar** — no Dock icon, minimal footprint
- **Bilingual** — supports English and Simplified Chinese

## Requirements

- macOS 14 (Sonoma) or later
- [duti](https://github.com/moretension/duti) — required to modify default applications

### Installing duti

```bash
brew install duti
```

If Homebrew is not installed, follow the instructions at [brew.sh](https://brew.sh).

## Building from Source

### Using Xcode

1. Open the project folder in Xcode (`File > Open…`, select the `DutiUI` folder)
2. Select the `DutiUI` scheme
3. Press `⌘B` to build or `⌘R` to run

### Using Command Line

```bash
swift build
swift run
```

## Usage

### First Launch

1. Click the shield icon in the menu bar
2. The main window opens — it's empty
3. Click **Add File Type** to search for extensions you want to manage
4. Select a default app for each extension
5. Toggle **Lock** to enable protection

### Locking Behavior

> **Important**: DutiUI's "lock" is **not** a system-level block. It works by:
> 1. Periodically checking the current default app for each locked extension
> 2. If the default app has changed, automatically restoring your preference
>
> This means another app can still temporarily change the association, but DutiUI will restore it within the check interval (default: 10 seconds).

### Closing the Window

- Closing the main window does **not** quit DutiUI
- The app continues running in the background
- Protection remains active
- Click the menu bar icon to reopen the window
- To quit, right-click the menu bar icon and select **Quit DutiUI**

> **Note**: When you quit DutiUI, automatic protection stops. Associations that were changed while DutiUI was not running will not be restored until you restart.

## Settings

Access settings via the menu bar icon or `DutiUI > Settings…` (`⌘,`).

- **Launch at Login**: Automatically start DutiUI after logging in
- **Check Interval**: How often to check locked associations (5s / 10s / 30s / 60s)
- **Show Restore Notifications**: Send notifications when associations are auto-restored

## Privacy

DutiUI does **not**:
- Upload any data
- Read file contents
- Require Full Disk Access
- Require Accessibility permissions
- Require SIP to be disabled
- Require administrator privileges

It only processes file extension names and default application associations using public macOS APIs and the `duti` command-line tool.

## Limitations

- v1.0 does not show all system UTI types — only user-selected extensions
- The lock is detection-based, not a system-level block
- Requires `duti` to be installed separately
- No Finder extension or Spotlight integration
- No iCloud sync or multiple profiles
- Does not determine which specific app changed an association

## License

MIT License — see [LICENSE](LICENSE) for details.

## Acknowledgments

- [duti](https://github.com/moretension/duti) — the essential tool for setting default apps on macOS
