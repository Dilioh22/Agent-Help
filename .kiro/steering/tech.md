# Technical Stack

## Primary Language

**Dart**: All Flutter framework code is written in Dart. The project requires strict type checking with strict-casts, strict-inference, and strict-raw-types enabled.

## Build System & Tools

- **Flutter CLI**: Primary development tool (`flutter` command)
- **Dart SDK**: Automatically downloaded by Flutter on first run
- **Git**: Version control and source management
- **Python**: Used by various build and automation scripts

## Key Dependencies

- **flutter_test**: Testing framework with Flutter-specific extensions
- **flutter_driver**: End-to-end testing on real devices/emulators
- **Skia/Impeller**: 2D graphics rendering engines (C++ in engine repository)

## Code Quality Tools

- **Dart Analyzer**: Static analysis with comprehensive linter rules (see `analysis_options.yaml`)
- **dart format**: Code formatting with 100-character line width
- **Coverage Tools**: Test coverage tracking for package:flutter

## Common Commands

### Setup & Configuration
```bash
# Initial setup after cloning
flutter update-packages

# For IntelliJ users
flutter ide-config --overwrite
```

### Testing
```bash
# Run all tests in a package
flutter test

# Run specific test file
flutter test lib/my_app_test.dart

# Run with local engine build
flutter test --local-engine=host_debug_unopt --local-engine-host=host_debug_unopt

# Run tests with debugger support
flutter test --start-paused

# Run complete CI test suite (as LUCI does)
dart dev/bots/test.dart
dart --enable-asserts dev/bots/analyze.dart
```

### Running Examples
```bash
# Run example apps
cd examples/hello_world
flutter run

# View test visually on device
flutter run test/my_test.dart
```

### Analysis
```bash
# Run static analysis
flutter analyze

# Check formatting
dart format --set-exit-if-changed .
```

### Development
```bash
# Add flutter to PATH
export PATH="$PATH:$HOME/<path-to-flutter>/bin"

# Check Flutter configuration
flutter doctor
```

## Platform-Specific Requirements

- **Android**: Android platform tools (`adb` must be in PATH)
- **iOS/macOS**: Xcode and CocoaPods
- **Linux**: `android-tools-adb` package
- **Windows**: Windows SDK

## Testing Infrastructure

- **Unit Tests**: Using `flutter_test` package, placed in `test/` directories with `_test.dart` suffix
- **Golden Tests**: Pixel-comparison tests for visual regression detection
- **Device Lab**: Physical device testing infrastructure
- **CI/CD**: LUCI-based continuous integration with pre-commit and post-commit tests

## Architecture

- **Layered Design**: Each layer solves a narrowly scoped problem
  - Widgets layer (high-level, composable UI components)
  - Rendering layer (layout and painting)
  - Painting layer (low-level graphics primitives)
- **Hot Reload**: Stateful code reloading without app restart
- **Platform Channels**: FFI and platform-specific API integration
