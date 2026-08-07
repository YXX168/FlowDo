# FlowDo

Fluid Todo App for Android (ARM64) built with Flutter.

## Features

- Bottom-weighted liquid animated background
- Layered, lightweight glass panels optimized for narrow screens
- Priority-based todo management (High / Medium / Low)
- Filter tabs (All / Active / Completed)
- Statistics with progress bar
- Search, editing, swipe-to-delete, undo, and filtered drag-to-reorder
- Validated local JSON storage with serialized atomic writes and recovery backup
- Custom adaptive Android launcher icon

## Build

This project uses GitHub Actions for all validation and cloud compilation. A
push to `main` runs static analysis, unit tests, shader
compilation, and the ARM64 release build.

The APK artifact will be available in the Actions tab as `flowdo-arm64-apk`.

The Android runner structure is generated in CI, so no local Flutter toolchain
is required to produce a release artifact.

## Release signing

Release APKs from version `2.3.0` onward use the persistent FlowDo production
certificate stored in GitHub Actions Secrets. CI verifies the finished APK
certificate before uploading it. Certificate SHA-256:

`1B5D5D959CF9A9317C18375541E0D26A7F0F4578940CB00739AC0E9F72C75CF5`

Builds older than `2.3.0` used an ephemeral debug certificate and must be
uninstalled once before installing the first production-signed APK. Future
production-signed versions can be installed as normal in-place upgrades.

## Tech Stack

- Flutter
- Dart
- CustomPainter for fluid background animation
- path_provider for local JSON storage
