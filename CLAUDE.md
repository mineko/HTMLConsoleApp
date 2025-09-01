# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HTMLConsoleApp is a SwiftUI-based iOS/macOS application created with Xcode. This is a basic SwiftUI app with a simple "Hello, world!" interface.

## Common Development Commands

### Building
```bash
# Build the project
xcodebuild -project HTMLConsoleApp.xcodeproj -scheme HTMLConsoleApp -configuration Debug build

# Build for release
xcodebuild -project HTMLConsoleApp.xcodeproj -scheme HTMLConsoleApp -configuration Release build
```

### Testing
```bash
# Run unit tests
xcodebuild test -project HTMLConsoleApp.xcodeproj -scheme HTMLConsoleApp -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test target
xcodebuild test -project HTMLConsoleApp.xcodeproj -target HTMLConsoleAppTests

# Run UI tests
xcodebuild test -project HTMLConsoleApp.xcodeproj -target HTMLConsoleAppUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Code Analysis
```bash
# Analyze code for issues
xcodebuild analyze -project HTMLConsoleApp.xcodeproj -scheme HTMLConsoleApp
```

## Architecture

- **Main App**: `HTMLConsoleAppApp.swift` - SwiftUI app entry point
- **UI**: `ContentView.swift` - Primary view with basic "Hello, world!" content
- **Tests**: 
  - `HTMLConsoleAppTests/` - Unit tests using Swift Testing framework
  - `HTMLConsoleAppUITests/` - UI tests using XCTest framework
- **Assets**: `Assets.xcassets/` - App icons and color assets

## Testing Framework

- Unit tests use the modern Swift Testing framework (`import Testing`)
- UI tests use XCTest framework with XCUIApplication
- Test files follow naming convention: `[Target]Tests.swift`

## Project Configuration

- **Targets**: HTMLConsoleApp (main), HTMLConsoleAppTests, HTMLConsoleAppUITests
- **Build Configurations**: Debug, Release (defaults to Release)
- **Default Scheme**: HTMLConsoleApp