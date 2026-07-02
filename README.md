# TuckBar

TuckBar is a GitHub-distributed macOS menu-bar organizer. It adds one menu-bar icon that opens a compact vertical shelf for selected status items, then forwards clicks to the backing menu-bar item through macOS Accessibility.

The app is intentionally outside the Mac App Store sandbox. Public AppKit APIs only manage an app's own `NSStatusItem`, so discovery and click forwarding for other apps use Accessibility. Fully hiding third-party menu-bar icons is treated as experimental: when macOS or a target app blocks hiding, TuckBar keeps the original icon visible and still shows the item in the shelf.

## Current Features

- Menu-bar app with a single TuckBar status icon.
- Dock icon visibility toggle, visible by default while the app is being debugged.
- Accessibility-based discovery of `AXExtrasMenuBar` and `AXMenuBarItem` items.
- Vertical shelf anchored below the TuckBar icon.
- Click forwarding via `AXPress`.
- Persisted item identity, order, placement mode, last seen time, and fallback hiding status.
- Placement modes: `Real`, `Shelf`, and `Both`.
- Drag reordering inside the shelf.
- Local `.app` bundling and zip packaging scripts.

## Requirements

- macOS 14 or newer
- Xcode command line tools
- Accessibility permission for TuckBar

## Build And Run

```bash
./script/build_and_run.sh
```

The script builds the SwiftPM executable, stages `dist/TuckBar.app`, and launches it as a real app bundle.

Useful modes:

```bash
./script/build_and_run.sh --verify
./script/build_and_run.sh --logs
./script/build_and_run.sh --telemetry
```

## Package A Release

```bash
./script/package_release.sh
```

The release zip is written to:

```text
dist/TuckBar.zip
```

## Tests

```bash
swift test
```

## Permissions

On first launch, open the TuckBar shelf and choose the permission button if needed. macOS will route you to System Settings so TuckBar can be enabled under Privacy & Security > Accessibility.

## Status

This is an MVP. Discovery and click forwarding are implemented first; third-party icon hiding remains fallback-only until each target app and macOS version proves it supports a reliable hiding path.
