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
    private var imagePlacementRestricted: Bool = false
    private var lastImageTime: TimeInterval = 0
    private var linesSinceClearance: Int = 0
    private let requiredLinesAfterClearance: Int = 3
    
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
        if !availableImages.isEmpty && Int.random(in: 1...2) == 1 {
            addRandomImage()
        }
        
        controller.showPrompt()
    }
    
    private func addRandomImage() {
        guard let controller = controller,
              let randomImage = availableImages.randomElement() else { return }
        
        let currentTime = Date().timeIntervalSince1970
        
        // Prevent rapid successive image placements (minimum 1 second between images)
        if currentTime - lastImageTime < 1.0 {
            print("DEBUG: IMAGE PLACEMENT - Too soon after last image, skipping")
            return
        }
        
        // Random size: small, medium, or large
        let sizes = ["small", "medium", "large"]
        let randomSize = sizes.randomElement() ?? "medium"
        
        // Smart side selection with clearance detection
        let proposedAlignment = selectImageAlignment()
        
        // Smart image placement with real-time clearance checking
        if !imagePlacementRestricted {
            // Check if we're still in the buffer period after clearance
            if linesSinceClearance < requiredLinesAfterClearance {
                print("DEBUG: IMAGE PLACEMENT - In buffer period (\(linesSinceClearance)/\(requiredLinesAfterClearance) lines), skipping image")
                return
            }
            
            // No restriction and buffer period passed - place image
            print("DEBUG: IMAGE PLACEMENT - No restriction, placing first \(proposedAlignment) image")
            let timestamp = Date().timeIntervalSince1970
            controller.addImageWithTimestamp(randomImage, alignment: proposedAlignment, size: randomSize, timestamp: timestamp)
            controller.addOutput("\nImage Size: " + randomSize + "\n")
            imagePlacementRestricted = true
            lastImageTime = timestamp
            linesSinceClearance = 0  // Reset buffer counter when placing new image
        } else {
            // There's a restriction - check if clearance exists before placing
            print("DEBUG: IMAGE PLACEMENT - Restriction active, checking clearance for \(proposedAlignment) image")
            checkClearanceAndPlaceImage(image: randomImage, alignment: proposedAlignment, size: randomSize)
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
    
    // Method for ConsoleController to call after adding output text
    func checkTextFlowClearance() {
        // Count lines after clearance to add buffer
        if !imagePlacementRestricted && linesSinceClearance < requiredLinesAfterClearance {
            linesSinceClearance += 1
            print("DEBUG: BUFFER - Line \(linesSinceClearance) of \(requiredLinesAfterClearance) after clearance")
        }
    }
    
    private func checkClearanceAndPlaceImage(image: String, alignment: String, size: String) {
        guard let controller = controller else { return }
        
        // Check clearance for the most recent image before placing new image
        let script = "window.hasTextFlowedBelowMostRecentImage(\(lastImageTime))"
        
        controller.evaluateJavaScript(script) { [weak self] result, error in
            DispatchQueue.main.async {
                if let hasTextFlowed = result as? Bool, hasTextFlowed {
                    // Clearance exists - clear restriction and start buffer period
                    print("DEBUG: Clearance detected, clearing restriction and starting buffer period")
                    self?.imagePlacementRestricted = false
                    self?.linesSinceClearance = 0  // Start buffer period
                    
                    // Don't place the image yet - it will be attempted again after buffer period
                    print("DEBUG: Image placement deferred until after buffer period")
                } else {
                    // No clearance - reject the image placement
                    print("DEBUG: No clearance, rejecting \(alignment) image")
                    // Don't place image, don't update lastImageSide
                }
            }
        }
    }
}
