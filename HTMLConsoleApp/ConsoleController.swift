//
//  ConsoleController.swift
//  HTMLConsoleApp
//
//  Created by Collin Pieper on 9/1/25.
//

import Foundation
import WebKit

// Console controller to handle input/output logic
class ConsoleController: NSObject, ObservableObject {
    private weak var webView: WKWebView?
    private var availableThemes: [String] = []
    private var currentTheme: String
    private var menuManager: MenuManager!
    private var statusBar: StatusBar?
    
    override init() {
        // Initialize with placeholder values
        self.availableThemes = []
        self.currentTheme = "default"
        super.init()
        
        // Dynamically discover CSS files in the bundle after super.init()
        self.availableThemes = self.discoverAvailableThemes()
        // Pick a random theme at initialization
        self.currentTheme = availableThemes.randomElement() ?? "default"
        
        // Create menu manager
        self.menuManager = MenuManager(controller: self)
        
        // Create status bar
        self.statusBar = StatusBar(controller: self)
    }
    
    private func discoverAvailableThemes() -> [String] {
        guard let bundlePath = Bundle.main.resourcePath else { 
            return ["default"] 
        }
        
        // Since Xcode flattens the directory structure, look for CSS files in the root
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
            let cssFiles = contents
                .filter { $0.hasSuffix(".css") }
                .map { String($0.dropLast(4)) } // Remove .css extension
                .sorted()
            
            return cssFiles.isEmpty ? ["default"] : cssFiles
        } catch {
            return ["default"]
        }
    }
    
    func getHTMLFileURL() -> URL? {
        return Bundle.main.url(forResource: "console", withExtension: "html")
    }
    
    func getSelectedTheme() -> String {
        return currentTheme
    }
    
    func getCurrentTheme() -> String {
        return currentTheme
    }
    
    func switchTheme(to themeName: String) {
        guard let webView = webView else { return }
        currentTheme = themeName
        let script = "document.querySelector('link[rel=\"stylesheet\"]').href = '\(themeName).css';"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    func setWebView(_ webView: WKWebView) {
        self.webView = webView
    }
    
    func start() {
        showWelcomeMessage()
        // Switch to the selected theme immediately after WebView loads
        switchTheme(to: currentTheme)
    }
    
    private func showWelcomeMessage() {
        // Show status bar with sample content
        statusBar?.setLines([
            StatusLine.leftRight(left: "HTMLConsole v1.0", right: "Ready"),
            StatusLine.leftCenterRight(left: "Theme: \(currentTheme)", center: "Status Demo", right: "Connected")
        ])
        statusBar?.show()
        
        addOutput("Welcome to HTMLConsole")
        addOutput("Type something and press Enter...")
        showPrompt()
    }
    
    func showPrompt() {
        guard let webView = webView else { return }
        let script = "showPrompt();"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    func hidePrompt() {
        guard let webView = webView else { return }
        let script = "hidePrompt();"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    func processInput(_ input: String) {
        // Only handle normal user input - menu actions are handled separately
        if input == "/" {
            menuManager.showRootMenu()
        } else if input.hasPrefix("/") {
            // Try to navigate to a menu path
            if menuManager.navigateToPath(input) {
                // Successfully navigated to menu path
                return
            } else {
                // Path not found, show temporary error message
                showError("Menu path not found: \(input)")
                showPrompt()
                return
            }
        } else {
            // Normal echo functionality
            addOutput("\n" + input)
            showPrompt()
        }
    }
    
    func handleMenuAction(_ action: String) {
        // If not in menu mode, ignore the action
        guard menuManager.isInMenuMode else { return }
        
        if action.hasPrefix("SELECT:") {
            let indexString = String(action.dropFirst(7)) // Remove "SELECT:" prefix
            if let index = Int(indexString) {
                menuManager.selectItem(at: index)
            }
        } else if action == "CANCEL" {
            menuManager.exitMenu()
        }
    }
    
    // Methods for MenuManager to call
    internal func getAvailableThemes() -> [String] {
        return availableThemes
    }
    
    // Interface methods for MenuManager
    internal func showSubmenu(_ submenu: Menu?) {
        guard let submenu = submenu else { return }
        menuManager.showSubmenu(submenu)
    }
    
    internal func goBackInMenu() {
        menuManager.goBack()
    }
    
    internal func exitMenu() {
        menuManager.exitMenu()
    }
    
    // Method called by MenuManager to display menu
    internal func displayMenu(items: [MenuItem], title: String) {
        guard let webView = webView else { return }
        
        let itemTitles = items.map { $0.title }
        let itemsJSON = try! JSONSerialization.data(withJSONObject: itemTitles, options: [])
        let itemsString = String(data: itemsJSON, encoding: .utf8)!
        
        let escapedTitle = title.replacingOccurrences(of: "'", with: "\\'")
        let script = "showMenu({title: '\(escapedTitle)', items: \(itemsString)});"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    // Method called by MenuManager to hide menu
    internal func hideMenu() {
        guard let webView = webView else { return }
        let script = "hideMenu();"
        webView.evaluateJavaScript(script, completionHandler: nil)
        showPrompt()
    }
    
    // Show temporary error message
    private func showError(_ message: String) {
        guard let webView = webView else { return }
        
        let escapedMessage = message.replacingOccurrences(of: "\\", with: "\\\\")
                                    .replacingOccurrences(of: "'", with: "\\'")
        
        let script = "showError('\(escapedMessage)');"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    func addOutput(_ text: String) {
        guard let webView = webView else { return }
        
        let escapedText = text.replacingOccurrences(of: "\\", with: "\\\\")
                             .replacingOccurrences(of: "'", with: "\\'")
                             .replacingOccurrences(of: "\n", with: "\\n")
        
        let script = "addOutput('\(escapedText)');"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    // StatusBar methods
    internal func displayStatusBar(lines: [StatusLine]) {
        guard let webView = webView else { return }
        
        let linesData = lines.map { line in
            let regionsData = line.regions.map { region in
                ["text": region.text, "alignment": "\(region.alignment)"]
            }
            return ["regions": regionsData]
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: linesData, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)!
            let script = "showStatusBar(\(jsonString));"
            webView.evaluateJavaScript(script, completionHandler: nil)
        } catch {
            print("Error serializing status bar data: \(error)")
        }
    }
    
    internal func hideStatusBar() {
        guard let webView = webView else { return }
        let script = "hideStatusBar();"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    // Public methods for StatusBar access
    func getStatusBar() -> StatusBar? {
        return statusBar
    }
}
