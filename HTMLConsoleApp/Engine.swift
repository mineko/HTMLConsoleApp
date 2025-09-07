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
    
    init(controller: ConsoleController) {
        self.controller = controller
    }
    
    // Display the welcome message and initialize the console
    func start() {
        guard let controller = controller else { return }
        
        // Show status bar with sample content
        controller.getStatusBar()?.setLines([
            StatusLine.leftCenterRight(left: "HTMLConsole v1.0", center: "Status Demo", right: "Ready"),
            StatusLine.leftRight(left: "Theme: \(controller.getCurrentTheme())", right: "Connected")
        ])
        controller.getStatusBar()?.show()
        
        controller.addOutput("Welcome to HTMLConsole")
        controller.addOutput("Type something and press Enter...")
        controller.showPrompt()
    }
    
    // Handle echo functionality for normal user input
    func processInput(_ input: String) {
        guard let controller = controller else { return }
        
        controller.addOutput("\n" + input)
        controller.showPrompt()
    }
}
