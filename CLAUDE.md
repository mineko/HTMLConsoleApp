# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HTMLConsoleApp is a modular SwiftUI-based macOS application that provides a Terminal.app-like HTML console interface. Modules (text adventures, RPGs, etc.) plug into the console framework to provide interactive experiences.

## Common Development Commands

### Building
```bash
# Build the Swift Package (ConsoleKit + TestModule)
cd Packages/ConsoleKit && swift build

# Build the Xcode project
xcodebuild -project HTMLConsoleApp.xcodeproj -scheme HTMLConsoleApp -configuration Debug build

# Build for release
xcodebuild -project HTMLConsoleApp.xcodeproj -scheme HTMLConsoleApp -configuration Release build
```

### Testing
```bash
# Run unit tests
xcodebuild test -project HTMLConsoleApp.xcodeproj -scheme HTMLConsoleApp -destination 'platform=macOS'

# Run specific test target
xcodebuild test -project HTMLConsoleApp.xcodeproj -target HTMLConsoleAppTests

# Run UI tests
xcodebuild test -project HTMLConsoleApp.xcodeproj -target HTMLConsoleAppUITests -destination 'platform=macOS'
```

### Code Analysis
```bash
xcodebuild analyze -project HTMLConsoleApp.xcodeproj -scheme HTMLConsoleApp
```

## Architecture

### Package Structure

The core framework lives in a local Swift Package at `Packages/ConsoleKit/`:

- **ConsoleKit** library target — reusable console infrastructure:
  - `ConsoleView.swift` — SwiftUI view hosting the WKWebView console (drop into any window/pane)
  - `ConsoleController.swift` — Bridges WebView JS ↔ Swift, manages themes/menu/status bar
  - `Engine.swift` — `open class` base for module engines (subclass to add behavior)
  - `ModuleProtocol.swift` — `ConsoleModule` protocol and `ModuleInfo` struct
  - `ModuleRegistry.swift` — Compile-time module registration (iOS-safe, no dynamic loading)
  - `MenuManager.swift` — In-console menu system (activated with `/`)
  - `StatusBar.swift` — Multi-line status bar with named fields
  - `Resources/` — `console.html`, theme CSS files (Dark, Light, Homebrew, Monospace, Retro, Serif)

- **TestModule** library target — demo module:
  - `TestModule.swift` — Implements `ConsoleModule`, contains `TestEngine` (echoes input, shows random images)
  - `Resources/test.bundle/` — Module data (info.json, images/)

### App Target

`HTMLConsoleApp/` is a thin shell:
- `HTMLConsoleApp.swift` — Registers modules in `init()`, shows `ConsoleView`
- `Assets.xcassets/` — App icons and color assets

### Adding a New Module

1. Create a new target in `Packages/ConsoleKit/Package.swift` depending on `ConsoleKit`
2. Implement `ConsoleModule` protocol (provides `moduleInfo` and `createEngine()`)
3. Subclass `Engine` — override `start()`, `processInput()`, `configureStatusBar()`
4. Register in the app: `ModuleRegistry.shared.register(YourModule.self)`

### Console Communication Flow

1. User types in HTML input → JS sends to Swift via `window.webkit.messageHandlers.consoleInput.postMessage()`
2. `ConsoleController.processInput()` routes to menu system or delegates to engine
3. Engine calls `addOutput()`/`addContent()` → `evaluateJavaScript()` → DOM update
4. Resources use `Bundle.module` (SPM-generated) not `Bundle.main`

## Testing Framework

- Unit tests use the modern Swift Testing framework (`import Testing`)
- UI tests use XCTest framework with XCUIApplication
- Test files follow naming convention: `[Target]Tests.swift`

## Project Configuration

- **Targets**: HTMLConsoleApp (main), HTMLConsoleAppTests, HTMLConsoleAppUITests
- **Build Configurations**: Debug, Release (defaults to Release)
- **Default Scheme**: HTMLConsoleApp
- **Platform**: macOS (iOS planned)
