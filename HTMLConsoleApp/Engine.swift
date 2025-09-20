//
//  Engine.swift
//  HTMLConsoleApp
//
//  Created by Claude on 9/7/25.
//

import Foundation

// Module configuration structure
struct ModuleInfo: Codable {
    let name: String
    let version: String
    let engineType: String
    let description: String?
    let author: String?
    let minAppVersion: String?
}

// Module bundle structure
struct ModuleBundle {
    let info: ModuleInfo
    let bundlePath: String
}

// Generic console engine providing base functionality
class Engine {
    internal weak var controller: ConsoleController?
    internal var statusBar: StatusBar?
    internal var moduleBundle: ModuleBundle?

    init(controller: ConsoleController, moduleBundle: ModuleBundle? = nil) {
        self.controller = controller
        self.statusBar = controller.getStatusBar()
        self.moduleBundle = moduleBundle

        configureStatusBar()
    }

    // MARK: - Module Loading

    // Find and load the first available module bundle
    static func loadFirstAvailableModule() -> ModuleBundle? {
        guard let bundlePath = Bundle.main.resourcePath else {
            print("Engine: Could not find bundle resource path")
            return nil
        }

        print("Engine: Searching for bundles in: \(bundlePath)")

        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
            print("Engine: Found files in Resources: \(contents.filter { $0.contains("bundle") || $0.contains("test") })")
            let bundleFiles = contents.filter { $0.hasSuffix(".bundle") }

            guard let firstBundle = bundleFiles.first else {
                print("Engine: No .bundle files found in Resources directory")
                print("Engine: Available files: \(contents.prefix(10))")
                return nil
            }

            let bundleFullPath = bundlePath + "/" + firstBundle
            print("Engine: Loading bundle from: \(bundleFullPath)")
            return loadModuleBundle(at: bundleFullPath)
        } catch {
            print("Engine: Error reading Resources directory: \(error)")
            return nil
        }
    }

    // Load a specific module bundle
    static func loadModuleBundle(at path: String) -> ModuleBundle? {
        let infoPath = path + "/info.json"

        print("Engine: Loading module bundle at: \(path)")
        print("Engine: Looking for info.json at: \(infoPath)")

        // Load and parse info.json
        guard let infoData = FileManager.default.contents(atPath: infoPath) else {
            print("Engine: Could not read info.json at path: \(infoPath)")
            // List what's actually in the directory
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: path)
                print("Engine: Bundle contents: \(contents)")
            } catch {
                print("Engine: Could not list bundle contents: \(error)")
            }
            return nil
        }

        do {
            let moduleInfo = try JSONDecoder().decode(ModuleInfo.self, from: infoData)
            print("Engine: Successfully loaded module: \(moduleInfo.name) v\(moduleInfo.version)")

            return ModuleBundle(
                info: moduleInfo,
                bundlePath: path
            )
        } catch {
            print("Engine: Error parsing info.json: \(error)")
            return nil
        }
    }

    // Create an engine instance based on module configuration
    static func createEngine(for moduleBundle: ModuleBundle, controller: ConsoleController) -> Engine {
        switch moduleBundle.info.engineType {
        case "TestEngine":
            return TestEngine(controller: controller, moduleBundle: moduleBundle)
        default:
            print("Unknown engine type: \(moduleBundle.info.engineType), falling back to base Engine")
            return Engine(controller: controller, moduleBundle: moduleBundle)
        }
    }
    
    // MARK: - Public Interface
    
    // Display the welcome message and initialize the console
    func start() {
        // Subclasses should override this method
    }
    
    // Handle user input - subclasses should override this
    func processInput(_ input: String) {
    }
    
    // MARK: - Helper Methods for Subclasses
    
    internal func addOutput(_ text: String) {
        controller?.addOutput(text)
    }
    
    internal func addContent(text: String = "", image: String = "", caption: String = "") {
        controller?.addContent(text: text, image: image, caption: caption)
    }
    
    // MARK: - Methods for Subclasses to Override
    
    // Subclasses should override this to provide custom welcome messages
    internal func showWelcomeMessage() {
    }
    
    // Subclasses should override this to configure their status bar
    func configureStatusBar() {
    }
}

