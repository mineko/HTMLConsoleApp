//
//  TestEngine.swift
//  HTMLConsoleApp
//
//  Created by Collin Pieper on 9/11/25.
//

import Foundation

// Test/Demo engine with image placement and echo functionality
class TestEngine: Engine {
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
        addOutput("Welcome to HTMLConsole Test Mode")
        addOutput("Type something and press Enter to see echo and random images...")
    }
    
    override func processInput(_ input: String) {
        addOutput("\n")
        addOutput(input)
        
        // Occasionally add a random image (100% chance for testing - was 1 in 1)
        if !availableImages.isEmpty && Int.random(in: 1...1) == 1 {
            addRandomImage()
        }
        
        controller?.showPrompt()
    }
    
    
    private func addRandomImage() {
        guard let randomImage = availableImages.randomElement() else { return }
        
        // Random size: small, medium, or large
        let sizes = ["small", "medium", "large"]
        let randomSize = sizes.randomElement() ?? "medium"
        
        // Random alignment: left, right, or center
        let proposedAlignment = selectImageAlignment()
        
        // Try to place the image - JavaScript handles all the logic
        tryPlaceImage(randomImage, alignment: proposedAlignment, size: randomSize) { wasPlaced in
            if wasPlaced {
                print("DEBUG: IMAGE PLACEMENT - Successfully placed \(proposedAlignment) image")
            } else {
                print("DEBUG: IMAGE PLACEMENT - Image placement deferred or rejected")
            }
        }
    }
    
    private func selectImageAlignment() -> String {
        // Random alignment: left, right, or center
        let alignments = ["left", "right", "center"]
        return alignments.randomElement() ?? "left"
    }
}
