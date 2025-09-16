//
//  TestEngine.swift
//  HTMLConsoleApp
//
//  Created by Collin Pieper on 9/11/25.
//

import Foundation

// Test/Demo engine with image placement and echo functionality
class TestEngine: Engine {
    private var inputCount: Int = 0
    private var availableImages: [String] = []
    
    override init(controller: ConsoleController) {
        super.init(controller: controller)
        self.availableImages = discoverAvailableImages()
    }
    
    private func discoverAvailableImages() -> [String] {
        guard let bundlePath = Bundle.main.resourcePath else {
            return []
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
            let imageFiles = contents
                .filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") || $0.hasSuffix(".gif") }
                .sorted()
            
            return imageFiles
        } catch {
            return []
        }
    }
    
    override func configureStatusBar() {
        statusBar?.setLineCount(1)
        
        // Register named fields
        statusBar?.registerField(name: "app_name", line: 0, alignment: .center)
        statusBar?.registerField(name: "input_count", line: 0, alignment: .left)
        statusBar?.registerField(name: "version", line: 0, alignment: .right)
        
        // Set initial field values
        statusBar?.updateField(name: "app_name", text: "Status Demo")
        statusBar?.updateField(name: "input_count", text: "Inputs: 0")
        statusBar?.updateField(name: "version", text: "Build 2025.09.07")
    }
    
    override func start() {
        statusBar?.show()
        showWelcomeMessage()
        controller?.showPrompt()
    }
    
    override internal func showWelcomeMessage() {
        addContent(text: "Welcome to HTMLConsole Test Mode")
        addContent(text: "Type something and press Enter to see responsive content layout...")
    }
    
    override func processInput(_ input: String) {
        incrementInputCount()
        
        // Add user input as text content
        addContent(text: "\n" + input)
        
        // Occasionally add content with a random image (50% chance)
        if !availableImages.isEmpty && Int.random(in: 1...2) == 1 {
            addRandomContent()
        }
        
        controller?.showPrompt()
    }
    
    
    private func addRandomContent() {
        guard let randomImage = availableImages.randomElement() else { return }
        
        // Randomly decide whether to add a caption (50% chance)
        let caption = Int.random(in: 1...2) == 1 ? randomImage : ""
        
        // Decide what type of content to add
        let contentType = Int.random(in: 1...4)
        
        switch contentType {
        case 1:
            // Text only
            addContent(text: "Some interesting text content about the current topic.")
        case 2:
            // Image only
            addContent(image: randomImage, caption: caption)
        case 3:
            // Text with image
            addContent(text: "Here's some descriptive text that goes with this image.", 
                      image: randomImage, 
                      caption: caption)
        case 4:
            // Just an image with caption
            addContent(image: randomImage, caption: caption.isEmpty ? "A random image" : caption)
        default:
            break
        }
        
        print("DEBUG: CONTENT - Added content with image: \(randomImage), caption: \(caption.isEmpty ? "none" : caption)")
    }
    
    func incrementInputCount() {
        inputCount += 1
        
        // Update input count in status bar
        statusBar?.updateField(name: "input_count", text: "Inputs: \(inputCount)")
    }
}
