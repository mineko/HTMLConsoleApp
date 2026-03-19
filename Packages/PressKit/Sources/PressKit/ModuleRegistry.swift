//
//  ModuleRegistry.swift
//  PressKit
//

import Foundation

/// Central registry for console modules. App targets register modules at launch;
/// ConsoleController queries the registry to create engines.
public class ModuleRegistry {
    public static let shared = ModuleRegistry()

    private var entries: [(info: ModuleInfo, factory: (ConsoleController, Any?) -> Engine)] = []

    private init() {}

    /// Register a module type.
    public func register(_ moduleType: any ConsoleModule.Type) {
        let info = moduleType.moduleInfo
        entries.append((info: info, factory: { controller, configuration in
            moduleType.createEngine(controller: controller, configuration: configuration)
        }))
    }

    /// All registered module infos, in registration order.
    public var availableModules: [ModuleInfo] {
        entries.map { $0.info }
    }

    /// Create an engine for a specific module by name.
    public func createEngine(named name: String, controller: ConsoleController, configuration: Any? = nil) -> Engine? {
        guard let entry = entries.first(where: { $0.info.name == name }) else { return nil }
        return entry.factory(controller, configuration)
    }

    /// Find the module that handles a given file extension.
    public func module(forFileExtension ext: String) -> ModuleInfo? {
        entries.first(where: { $0.info.fileExtensions.contains(ext) })?.info
    }

    /// Modules that don't handle any file types (interactive/non-disk modules).
    public var nonFileModules: [ModuleInfo] {
        entries.filter { $0.info.fileExtensions.isEmpty }.map { $0.info }
    }
}
