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
    
    init(controller: ConsoleController) {
        self.controller = controller
        self.statusBar = controller.getStatusBar()
    
        configureStatusBar()
    }
    
    func configureStatusBar() {
        // Configure status bar with named fields
        statusBar?.setLineCount(2)
        
        // Register named fields
        statusBar?.registerField(name: "app_name", line: 0, alignment: .left)
        statusBar?.registerField(name: "status", line: 0, alignment: .center)
        statusBar?.registerField(name: "ready", line: 0, alignment: .right)
        statusBar?.registerField(name: "input_count", line: 1, alignment: .left)
        statusBar?.registerField(name: "version", line: 1, alignment: .right)
        
        // Set initial field values
        statusBar?.updateField(name: "app_name", text: "HTMLConsole v1.0")
        statusBar?.updateField(name: "status", text: "Status Demo")
        statusBar?.updateField(name: "ready", text: "Ready")
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

        controller.addOutput("\n" + input)
        controller.showPrompt()
    }
    
    func incrementInputCount() {
        inputCount += 1
        
        // Update input count in status bar
        statusBar?.updateField(name: "input_count", text: "Inputs: \(inputCount)")
    } 
}
