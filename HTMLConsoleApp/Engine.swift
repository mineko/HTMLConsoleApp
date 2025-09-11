//
//  Engine.swift
//  HTMLConsoleApp
//
//  Created by Claude on 9/7/25.
//

import Foundation

// Core application engine handling console logic
class Engine {
    private weak var controller: ConsoleController?
    private var statusBar: StatusBar?
    private var inputCount: Int = 0
    private var availableImages: [String] = []
    
    init(controller: ConsoleController) {
        self.controller = controller
        self.statusBar = controller.getStatusBar()
        self.availableImages = discoverAvailableImages()
    
        configureStatusBar()
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
    
    func configureStatusBar() {
        // Configure status bar with named fields
        //statusBar?.setLineCount(2)
        statusBar?.setLineCount(1)
        
        // Register named fields
        statusBar?.registerField(name: "app_name", line: 0, alignment: .center)
        //statusBar?.registerField(name: "status", line: 0, alignment: .center)
        //statusBar?.registerField(name: "ready", line: 0, alignment: .right)
        statusBar?.registerField(name: "input_count", line: 0, alignment: .left)
        statusBar?.registerField(name: "version", line: 0, alignment: .right)
        
        // Set initial field values
//        statusBar?.updateField(name: "app_name", text: "HTMLConsole v1.0")
    statusBar?.updateField(name: "app_name", text: "Status Demo")
    //    statusBar?.updateField(name: "ready", text: "Ready")
        statusBar?.updateField(name: "input_count", text: "Inputs: 0")
        statusBar?.updateField(name: "version", text: "Build 2025.09.07")
    }
    
    // Display the welcome message and initialize the console
    func start() {
        guard let controller = controller else { return }
        
        statusBar?.show()
        
        controller.addOutput("Welcome to HTMLConsole")
        controller.addOutput("Type something and press Enter...")
        controller.showPrompt()
    }
    
    // Handle echo functionality for normal user input
    func processInput(_ input: String) {
        guard let controller = controller else { return }
        
        incrementInputCount()

        controller.addOutput("\n")
        
        controller.addOutput(input)
        
        
        // Occasionally add a random image (20% chance) after the text output
        if !availableImages.isEmpty && Int.random(in: 1...1) == 1 {
            addRandomImage()
        }
        
        controller.showPrompt()
    }
    
    private func addRandomImage() {
        guard let controller = controller,
              let randomImage = availableImages.randomElement() else { return }
        
        // Random size: small, medium, or large
        let sizes = ["small", "medium", "large"]
        let randomSize = sizes.randomElement() ?? "medium"
        
        // Random alignment: left, right, or center
        let proposedAlignment = selectImageAlignment()
        
        // Try to place the image - JavaScript handles all the logic
        controller.tryPlaceImage(randomImage, alignment: proposedAlignment, size: randomSize) { wasPlaced in
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
    
    
    func incrementInputCount() {
        inputCount += 1
        
        // Update input count in status bar
        statusBar?.updateField(name: "input_count", text: "Inputs: \(inputCount)")
    }
}
