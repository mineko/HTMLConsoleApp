//
//  ModuleProtocol.swift
//  PressKit
//

import Foundation

/// Metadata describing a console module.
public struct ModuleInfo {
    public let name: String
    public let version: String
    public let description: String?
    public let author: String?
    public let minAppVersion: String?
    /// File extensions this module can open (e.g. ["pulpb"]). Empty for non-file modules.
    public let fileExtensions: [String]

    public init(
        name: String,
        version: String,
        description: String? = nil,
        author: String? = nil,
        minAppVersion: String? = nil,
        fileExtensions: [String] = []
    ) {
        self.name = name
        self.version = version
        self.description = description
        self.author = author
        self.minAppVersion = minAppVersion
        self.fileExtensions = fileExtensions
    }
}

/// Protocol that console modules implement to register themselves.
public protocol ConsoleModule {
    static var moduleInfo: ModuleInfo { get }
    static func createEngine(controller: ConsoleController, configuration: Any?) -> Engine
}
