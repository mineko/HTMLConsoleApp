//
//  TestModule.swift
//  TestModule
//

import Foundation
import PressKit

/// Demo module that echoes input and displays random images.
public struct TestModule: ConsoleModule {
    public static var moduleInfo: ModuleInfo {
        ModuleInfo(
            name: "Test Module",
            version: "1.0.0",
            description: "Demo engine with image placement and echo functionality",
            author: "Press",
            minAppVersion: "1.0.0"
        )
    }

    public static func createEngine(controller: ConsoleController, configuration: Any?) -> Engine {
        return TestEngine(controller: controller)
    }
}

// MARK: - TestEngine

class TestEngine: Engine {
    private var inputCount: Int = 0
    private var availableImages: [String] = []

    override init(controller: ConsoleController) {
        super.init(controller: controller)
        self.availableImages = Self.discoverImages()
        print("TestEngine: Initialized with \(availableImages.count) images")
    }

    // MARK: - Image Discovery

    private static func discoverImages() -> [String] {
        guard let imagesURL = Bundle.module.resourceURL?
                .appendingPathComponent("images") else {
            print("TestEngine: Could not find images in module resources")
            return []
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: imagesURL, includingPropertiesForKeys: nil)
            let imageFiles = contents
                .compactMap { $0.lastPathComponent }
                .filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") || $0.hasSuffix(".gif") }
                .sorted()
            print("TestEngine: Discovered \(imageFiles.count) images")
            return imageFiles
        } catch {
            print("TestEngine: Error reading images: \(error)")
            return []
        }
    }

    private func getImagePath(for imageName: String) -> String? {
        guard let imagesURL = Bundle.module.resourceURL?
                .appendingPathComponent("images") else {
            return nil
        }

        let imageURL = imagesURL.appendingPathComponent(imageName)
        if FileManager.default.fileExists(atPath: imageURL.path) {
            return imageURL.absoluteString
        }
        return nil
    }

    // MARK: - Engine Overrides

    override func moduleBundlePath() -> String? {
        return Bundle.module.resourcePath
    }

    override func configureStatusBar() {
        statusBar?.setLineCount(1)
        statusBar?.registerField(name: "module_name", line: 0, alignment: .center)
        statusBar?.registerField(name: "input_count", line: 0, alignment: .left)
        statusBar?.registerField(name: "image_count", line: 0, alignment: .right)

        statusBar?.updateField(name: "module_name", text: TestModule.moduleInfo.name)
        statusBar?.updateField(name: "input_count", text: "Inputs: 0")
        statusBar?.updateField(name: "image_count", text: "Images: \(availableImages.count)")
    }

    override func start() {
        statusBar?.show()
        showWelcomeMessage()
        controller?.showPrompt()
    }

    private func showWelcomeMessage() {
        let info = TestModule.moduleInfo
        addContent(text: "Welcome to \(info.name) v\(info.version)")
        if let description = info.description {
            addContent(text: description)
        }
        addContent(text: "Module loaded with \(availableImages.count) images available.")
        addContent(text: "Type something and press Enter to see responsive content layout...")
    }

    override func processInput(_ input: String) {
        inputCount += 1
        statusBar?.updateField(name: "input_count", text: "Inputs: \(inputCount)")

        addContent(text: "\n" + input)

        if !availableImages.isEmpty && Int.random(in: 1...2) == 1 {
            addRandomContent()
        }

        controller?.showPrompt()
    }

    private func addRandomContent() {
        guard let randomImageName = availableImages.randomElement(),
              let imagePath = getImagePath(for: randomImageName) else { return }

        let caption = Int.random(in: 1...2) == 1 ? randomImageName : ""

        switch Int.random(in: 1...4) {
        case 1:
            addContent(text: "Some interesting text content about the current topic.")
        case 2:
            addContent(image: imagePath, caption: caption)
        case 3:
            addContent(text: "Here's some descriptive text that goes with this image.",
                      image: imagePath, caption: caption)
        case 4:
            addContent(image: imagePath, caption: caption.isEmpty ? "A random image" : caption)
        default:
            break
        }
    }
}
