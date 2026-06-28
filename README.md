# Cliply

A lightweight, fast native macOS clipboard manager (inspired by Maccy).

Cliply lives in your menu bar, remembers everything you copy (text, images,
files, URLs, colors), and lets you search and reuse it instantly with the
keyboard.

## Status

Early development. Current focus:

- [x] Menu bar app skeleton
- [x] Clipboard history capture (polling)
- [x] Sensitive-content filtering
- [x] Fuzzy search over history
- [x] History popup with keyboard navigation
- [ ] Global hotkey
- [ ] Auto-paste into the previous app

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 16+ / Swift 6

## Build & Run

```bash
swift build
swift run
```

The app runs as a menu-bar accessory (no Dock icon). Click the menu bar icon
to open the history popup.
