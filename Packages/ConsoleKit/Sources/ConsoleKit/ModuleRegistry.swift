//
//  ModuleRegistry.swift
//  ConsoleKit
//

import Foundation

/// Central registry for console modules. App targets register modules at launch;
/// ConsoleController queries the registry to create engines.
public class ModuleRegistry {
    public static let shared = ModuleRegistry()

    private var entries: [(info: ModuleInfo, factory: (ConsoleController) -> Engine)] = []

    private init() {}

    /// Register a module type.
    public func register(_ moduleType: any ConsoleModule.Type) {
        let info = moduleType.moduleInfo
        entries.append((info: info, factory: { controller in
            moduleType.createEngine(controller: controller)
        }))
    }

    /// All registered module infos, in registration order.
    public var availableModules: [ModuleInfo] {
        entries.map { $0.info }
    }

    /// Create an engine for the first registered module (single-module apps).
    public func createDefaultEngine(controller: ConsoleController) -> Engine? {
        guard let entry = entries.first else { return nil }
        return entry.factory(controller)
    }

    /// Create an engine for a specific module by name.
    public func createEngine(named name: String, controller: ConsoleController) -> Engine? {
        guard let entry = entries.first(where: { $0.info.name == name }) else { return nil }
        return entry.factory(controller)
    }
}
