//
//  Engine.swift
//  HTMLConsoleApp
//
//  Created by Claude on 9/7/25.
//

import Foundation

// Generic console engine providing base functionality
class Engine {
    internal weak var controller: ConsoleController?
    internal var statusBar: StatusBar?
    
    init(controller: ConsoleController) {
        self.controller = controller
        self.statusBar = controller.getStatusBar()
        
        configureStatusBar()
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
    
    internal func addImage(_ imageName: String, alignment: String = "left", size: String = "medium") {
        controller?.addImage(imageName, alignment: alignment, size: size)
    }
    
    internal func tryPlaceImage(_ imageName: String, alignment: String, size: String, completion: @escaping (Bool) -> Void) {
        controller?.tryPlaceImage(imageName, alignment: alignment, size: size, completion: completion)
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

