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
        addContent(text: "Try 'cyoa' for a choice menu demo, or 'next' for a single-choice continuation.")
    }

    override func processInput(_ input: String) {
        inputCount += 1
        statusBar?.updateField(name: "input_count", text: "Inputs: \(inputCount)")

        addContent(text: "\n" + input)

        switch input.lowercased() {
        case "cyoa":
            startCyoaDemo()
            return
        case "next":
            startContinuationDemo()
            return
        default:
            break
        }

        if !availableImages.isEmpty && Int.random(in: 1...2) == 1 {
            addRandomContent()
        }

        controller?.showPrompt()
    }

    // MARK: - Modal Menu Demos

    private func startCyoaDemo() {
        addContent(text: "You stand at a fork in the road.")
        presentChoices(title: "Which way?", choices: [
            (title: "Go left, into the forest", action: { [weak self] in
                self?.addContent(text: "Branches close behind you. The path narrows.")
                self?.presentChoices(title: "The forest deepens…", choices: [
                    (title: "Press on",  action: { [weak self] in
                        self?.addContent(text: "You emerge into a moonlit clearing.")
                        self?.controller?.showPrompt()
                    }),
                    (title: "Turn back", action: { [weak self] in
                        self?.addContent(text: "You retreat to the fork, shaken.")
                        self?.controller?.showPrompt()
                    }),
                ])
            }),
            (title: "Go right, toward the cliffs", action: { [weak self] in
                self?.addContent(text: "Wind howls. The sea churns far below.")
                self?.controller?.showPrompt()
            }),
        ])
    }

    private func startContinuationDemo() {
        addContent(text: "A figure steps from the shadows.")
        presentChoices(title: "\"Well met, traveler.\"", choices: [
            (title: "Next", action: { [weak self] in
                self?.addContent(text: "They extend a hand. You hesitate.")
                self?.presentChoices(title: "\"Walk with me a while?\"", choices: [
                    (title: "Next", action: { [weak self] in
                        self?.addContent(text: "You fall in step beside them.")
                        self?.controller?.showPrompt()
                    }),
                ])
            }),
        ])
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
