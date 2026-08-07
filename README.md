# FlowDo

Fluid Todo App for Android (ARM64) built with Flutter.

## Features

- Liquid animated background (replicated from Mercury Music login page)
- Glassmorphism UI card
- Priority-based todo management (High / Medium / Low)
- Filter tabs (All / Active / Completed)
- Statistics with progress bar
- Search, editing, swipe-to-delete, undo, and filtered drag-to-reorder
- Validated local JSON storage with serialized atomic writes and recovery backup

## Build

This project uses GitHub Actions for all validation and cloud compilation. A
push to `main` runs static analysis, unit tests, shader
compilation, and the ARM64 release build.

The APK artifact will be available in the Actions tab as `flowdo-arm64-apk`.

The Android runner structure is generated in CI, so no local Flutter toolchain
is required to produce a release artifact.

## Tech Stack

- Flutter
- Dart
- CustomPainter for fluid background animation
- path_provider for local JSON storage
