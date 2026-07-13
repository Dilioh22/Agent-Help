# Project Structure

## Repository Organization

### Core Directories

- **`packages/`** - Core Flutter packages
  - `flutter/` - Main Flutter framework (widgets, rendering, painting, gestures, animation)
  - `flutter_test/` - Testing utilities and framework
  - `flutter_tools/` - Flutter command-line tool implementation
  - `flutter_driver/` - End-to-end testing framework
  - `flutter_localizations/` - Internationalization support
  - `flutter_web_plugins/` - Web-specific plugin infrastructure
  - `integration_test/` - Integration testing package

- **`examples/`** - Example applications demonstrating Flutter features
  - `hello_world/` - Minimal Flutter application
  - `api/` - API documentation examples
  - `layers/` - Low-level rendering and widget examples
  - `platform_channel/` - Platform integration examples
  - `flutter_view/` - Embedding Flutter in native apps

- **`dev/`** - Development tools and scripts
  - `bots/` - CI/CD scripts and automation
  - `devicelab/` - Physical device testing infrastructure
  - `tools/` - Development utilities
  - `benchmarks/` - Performance benchmarking
  - `a11y_assessments/` - Accessibility testing

- **`docs/`** - Development documentation and wiki content
  - `contributing/` - Contribution guidelines and processes
  - `about/` - Architecture and design philosophy
  - `engine/` - Engine development documentation
  - `releases/` - Release process documentation
  - `triage/` - Issue triage guidelines

- **`bin/`** - Flutter command-line executable and scripts

- **`engine/` (submodule)** - Flutter engine repository (C++, Java, Objective-C)

## File Naming Conventions

### Dart Files
- Regular code: `snake_case.dart`
- Tests: `*_test.dart` (must be in `test/` directory)
- Private implementations: Prefix with underscore `_internal.dart` (avoid when possible)

### Test Organization
- Organize into focused files by feature/widget/behavior
- Examples:
  - `button_layout_test.dart`
  - `button_semantics_test.dart`
  - `navigator_push_test.dart`
- Avoid large monolithic test files

## Configuration Files

- **`analysis_options.yaml`** - Dart analyzer configuration with strict linting rules
- **`dartdoc_options.yaml`** - API documentation generation settings
- **`pubspec.yaml`** - Dart package dependencies (per package)
- **`.ci.yaml`** - CI/CD configuration for automated testing
- **`DEPS`** - Engine dependency management

## Key Files

- **`CONTRIBUTING.md`** - Comprehensive contribution guide
- **`CODE_OF_CONDUCT.md`** - Community guidelines
- **`CODEOWNERS`** - Code ownership and review assignments
- **`AUTHORS`** - Contributor list
- **`LICENSE`** - BSD-style license
- **`CHANGELOG.md`** - Release notes and breaking changes

## Package Structure Pattern

Each package in `packages/` follows this structure:
```
package_name/
├── lib/
│   ├── src/           # Private implementation (not exported)
│   └── package.dart   # Public API exports
├── test/              # Unit tests (*_test.dart)
├── pubspec.yaml       # Package metadata and dependencies
├── analysis_options.yaml  # Package-specific linter overrides
├── LICENSE            # Package license
└── README.md          # Package documentation
```

## Module Organization Principles

1. **Layered Architecture**: Lower layers should not depend on higher layers
   - Painting → Rendering → Widgets
   
2. **Single Responsibility**: Each file/class addresses one narrowly scoped problem

3. **No Circular Dependencies**: Clear dependency hierarchy between packages

4. **Private by Default**: Implementation details in `src/`, only expose necessary APIs

5. **Test Co-location**: Tests mirror the structure of code being tested

## Special Directories

- **`agent-artifacts/`** - AI agent-generated artifacts (gitignored)
- **`bin/cache/`** - Downloaded SDK components (excluded from analysis)
- **`.dart_tool/`** - Dart build system artifacts (generated)
- **`buildtools/`** - Platform-specific build tools

## Documentation Structure

- Technical documentation lives in `docs/`
- API documentation generated from inline dartdoc comments
- Design documents use template at flutter.dev/go/template
- Style guide at `docs/contributing/Style-guide-for-Flutter-repo.md`
