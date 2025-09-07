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
    private var inputCount: Int = 0
    
    init(controller: ConsoleController) {
        self.controller = controller
    }
    
    // Display the welcome message and initialize the console
    func start() {
        guard let controller = controller else { return }
        
        // Configure status bar with named fields
        configureStatusBar(lines: 3)
        
        // Register named fields
        registerStatusField(name: "app_name", line: 0, alignment: .left)
        registerStatusField(name: "status", line: 0, alignment: .center)
        registerStatusField(name: "ready", line: 0, alignment: .right)
        registerStatusField(name: "theme", line: 1, alignment: .left)
        registerStatusField(name: "connection", line: 1, alignment: .right)
        registerStatusField(name: "input_count", line: 2, alignment: .left)
        registerStatusField(name: "version", line: 2, alignment: .right)
        
        // Set initial field values
        updateStatusField(name: "app_name", text: "HTMLConsole v1.0")
        updateStatusField(name: "status", text: "Status Demo")
        updateStatusField(name: "ready", text: "Ready")
        updateStatusField(name: "theme", text: "Theme: \(controller.getCurrentTheme())")
        updateStatusField(name: "connection", text: "Connected")
        updateStatusField(name: "input_count", text: "Inputs: 0")
        updateStatusField(name: "version", text: "Build 2025.09.07")
        
        controller.getStatusBar()?.show()
        
        controller.addOutput("Welcome to HTMLConsole")
        controller.addOutput("Type something and press Enter...")
        controller.showPrompt()
    }
    
    // Handle echo functionality for normal user input
    func processInput(_ input: String) {
        guard let controller = controller else { return }
        
        inputCount += 1
        
        // Update input count in status bar
        updateStatusField(name: "input_count", text: "Inputs: \(inputCount)")
        
        controller.addOutput("\n" + input)
        controller.showPrompt()
    }
    
    // Get the current input count
    func getInputCount() -> Int {
        return inputCount
    }
    
    // Configure status bar settings
    func configureStatusBar(lines: Int) {
        controller?.getStatusBar()?.setLineCount(lines)
    }
    
    // Register a named field in the status bar
    func registerStatusField(name: String, line: Int, alignment: StatusAlignment) {
        controller?.getStatusBar()?.registerField(name: name, line: line, alignment: alignment)
    }
    
    // Update a status field by name
    func updateStatusField(name: String, text: String) {
        controller?.getStatusBar()?.updateField(name: name, text: text)
    }
    
    // Update a status field by position
    func updateStatusField(line: Int, alignment: StatusAlignment, text: String) {
        controller?.getStatusBar()?.updateField(line: line, alignment: alignment, text: text)
    }
}
