//
//  HTMLConsoleController.swift
//  HTMLConsoleApp
//
//  Created by Collin Pieper on 9/1/25.
//

import Foundation
import WebKit

// Menu system data structures
struct MenuItem {
    let id: String
    let title: String
    let action: MenuAction
}

enum MenuAction {
    case submenu([MenuItem])
    case switchTheme(String)
    case cancel
}

enum MenuMode {
    case normal
    case menu(items: [MenuItem], selectedIndex: Int, title: String)
}

// Console controller to handle input/output logic
class HTMLConsoleController: NSObject, ObservableObject {
    private weak var webView: WKWebView?
    private var availableThemes: [String] = []
    private var currentTheme: String
    private var menuMode: MenuMode = .normal
    
    override init() {
        // Initialize with placeholder values
        self.availableThemes = []
        self.currentTheme = "default"
        super.init()
        
        // Dynamically discover CSS files in the bundle after super.init()
        self.availableThemes = self.discoverAvailableThemes()
        // Pick a random theme at initialization
        self.currentTheme = availableThemes.randomElement() ?? "default"
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
        switch menuMode {
        case .normal:
            if input == "/admin" {
                showAdminMenu()
            } else {
                // Normal echo functionality
                addOutput("\n" + input)
                showPrompt()
            }
        case .menu(let items, let selectedIndex, let title):
            // Menu navigation will be handled by JavaScript and sent as special commands
            if input == "MENU_SELECT:current" {
                selectMenuItem(items: items, index: selectedIndex)
            } else if input == "MENU_CANCEL" {
                exitMenu()
            } else if input.hasPrefix("MENU_NAVIGATE:") {
                let direction = String(input.dropFirst(14))
                navigateMenu(items: items, direction: direction, currentTitle: title)
            }
        }
    }
    
    private func showAdminMenu() {
        let themeItems = availableThemes.map { theme in
            MenuItem(id: "theme_\(theme)", title: theme, action: .switchTheme(theme))
        }
        
        let adminItems = [
            MenuItem(id: "theme_menu", title: "Theme", action: .submenu(themeItems)),
            MenuItem(id: "cancel", title: "Cancel", action: .cancel)
        ]
        
        menuMode = .menu(items: adminItems, selectedIndex: 0, title: "Admin Menu")
        renderMenu(items: adminItems, selectedIndex: 0, title: "Admin Menu")
    }
    
    private func selectMenuItem(items: [MenuItem], index: Int) {
        guard index >= 0 && index < items.count else { return }
        
        let selectedItem = items[index]
        
        switch selectedItem.action {
        case .submenu(let subItems):
            menuMode = .menu(items: subItems, selectedIndex: 0, title: selectedItem.title)
            renderMenu(items: subItems, selectedIndex: 0, title: selectedItem.title)
        case .switchTheme(let theme):
            switchTheme(to: theme)
            exitMenu()
        case .cancel:
            exitMenu()
        }
    }
    
    private func navigateMenu(items: [MenuItem], direction: String, currentTitle: String) {
        guard case .menu(_, let currentIndex, _) = menuMode else { return }
        
        var newIndex = currentIndex
        if direction == "up" {
            newIndex = max(0, currentIndex - 1)
        } else if direction == "down" {
            newIndex = min(items.count - 1, currentIndex + 1)
        }
        
        if newIndex != currentIndex {
            menuMode = .menu(items: items, selectedIndex: newIndex, title: currentTitle)
            redrawMenu(items: items, selectedIndex: newIndex, title: currentTitle)
        }
    }
    
    private func redrawMenu(items: [MenuItem], selectedIndex: Int, title: String) {
        // Clear the last rendered menu and redraw
        guard let webView = webView else { return }
        let clearScript = "clearLastMenu(\(items.count + 1));" // +1 for the title line
        webView.evaluateJavaScript(clearScript) { [weak self] _, _ in
            self?.renderMenu(items: items, selectedIndex: selectedIndex, title: title)
        }
    }
    
    private func renderMenu(items: [MenuItem], selectedIndex: Int, title: String) {
        hidePrompt()
        addOutput("\n=== \(title) ===\n")
        
        for (index, item) in items.enumerated() {
            addMenuLine(item.title, isSelected: index == selectedIndex)
        }
        
        // Enable menu navigation mode in JavaScript
        guard let webView = webView else { return }
        let script = "enableMenuMode();"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    private func addMenuLine(_ text: String, isSelected: Bool) {
        guard let webView = webView else { return }
        
        let escapedText = text.replacingOccurrences(of: "\\", with: "\\\\")
                             .replacingOccurrences(of: "'", with: "\\'")
                             .replacingOccurrences(of: "\n", with: "\\n")
        
        let className = isSelected ? "menu-selected" : ""
        let script = "addOutput('  \(escapedText)', '\(className)');"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    private func exitMenu() {
        menuMode = .normal
        addOutput("\n")
        showPrompt()
        
        // Disable menu navigation mode in JavaScript
        guard let webView = webView else { return }
        let script = "disableMenuMode();"
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
}
