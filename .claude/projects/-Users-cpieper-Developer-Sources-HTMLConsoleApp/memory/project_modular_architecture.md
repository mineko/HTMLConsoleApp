---
name: Modular console architecture
description: HTMLConsoleApp was refactored into a ConsoleKit Swift Package with a module registry pattern for pluggable engines
type: project
---

The app was restructured into a local Swift Package at `Packages/ConsoleKit/` with two library targets:

- **ConsoleKit**: Core framework (ConsoleView, ConsoleController, Engine base class, ModuleRegistry, MenuManager, StatusBar, HTML/CSS resources)
- **TestModule**: Demo module implementing ConsoleModule protocol with TestEngine

**Key patterns:**
- `ConsoleModule` protocol + `ModuleRegistry` for compile-time module registration (iOS-safe, no dynamic loading)
- `Engine` is an `open class` so modules in other packages can subclass it
- App target is a thin shell: registers modules in init(), shows `ConsoleView`
- Resources use `Bundle.module` (SPM auto-generated) instead of `Bundle.main`

**Why:** User wants to build multiple module types (CYOA, text RPG, solo RPG book adaptations) as separate targets, support a multi-module launcher app, embed the console in an IDE app, and eventually deploy on iOS.

**How to apply:** New modules go in new package targets depending on ConsoleKit. Each implements `ConsoleModule` and provides an `Engine` subclass. App targets choose which modules to compile in via package dependencies.
