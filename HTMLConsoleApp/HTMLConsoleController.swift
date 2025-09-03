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
    case back
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
    private var menuStack: [(items: [MenuItem], title: String)] = []
    
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
        case .menu(let items, _, _):
            if input.hasPrefix("MENU_SELECT:") {
                let parts = input.split(separator: ":", maxSplits: 2)
                if parts.count >= 2, let index = Int(parts[1]) {
                    selectMenuItem(items: items, index: index)
                }
            } else if input == "MENU_CANCEL" {
                exitMenu()
            }
        }
    }
    
    private func showAdminMenu() {
        let themeItems = availableThemes.map { theme in
            MenuItem(id: "theme_\(theme)", title: theme, action: .switchTheme(theme))
        }
        
        let adminItems = [
            MenuItem(id: "theme_menu", title: "Theme", action: .submenu(themeItems)),
            MenuItem(id: "separator", title: "", action: .cancel), // Empty item for spacing
            MenuItem(id: "cancel", title: "Cancel", action: .cancel)
        ]
        
        menuMode = .menu(items: adminItems, selectedIndex: 0, title: "Admin Menu")
        menuStack = [] // Clear menu stack for root menu
        sendMenuToJS(items: adminItems, title: "Admin Menu")
    }
    
    private func sendMenuToJS(items: [MenuItem], title: String) {
        guard let webView = webView else { return }
        
        let itemTitles = items.map { $0.title }
        let itemsJSON = try! JSONSerialization.data(withJSONObject: itemTitles, options: [])
        let itemsString = String(data: itemsJSON, encoding: .utf8)!
        
        let escapedTitle = title.replacingOccurrences(of: "'", with: "\\'")
        let script = "showMenu({title: '\(escapedTitle)', items: \(itemsString)});"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    private func selectMenuItem(items: [MenuItem], index: Int) {
        guard index >= 0 && index < items.count else { return }
        
        let selectedItem = items[index]
        
        switch selectedItem.action {
        case .submenu(let subItems):
            // Push current menu to stack before entering submenu
            menuStack.append((items: items, title: getCurrentMenuTitle()))
            
            // Create submenu with Back option
            let submenuItems = createSubmenuWithBack(subItems)
            menuMode = .menu(items: submenuItems, selectedIndex: 0, title: selectedItem.title)
            sendMenuToJS(items: submenuItems, title: selectedItem.title)
        case .switchTheme(let theme):
            switchTheme(to: theme)
            exitMenu()
        case .cancel:
            exitMenu()
        case .back:
            goBackInMenu()
        }
    }
    
    private func createSubmenuWithBack(_ items: [MenuItem]) -> [MenuItem] {
        var submenuItems = items
        submenuItems.append(MenuItem(id: "separator", title: "", action: .back)) // Empty item for spacing
        submenuItems.append(MenuItem(id: "back", title: "Back", action: .back))
        return submenuItems
    }
    
    private func goBackInMenu() {
        guard !menuStack.isEmpty else {
            exitMenu()
            return
        }
        
        let previousMenu = menuStack.removeLast()
        menuMode = .menu(items: previousMenu.items, selectedIndex: 0, title: previousMenu.title)
        sendMenuToJS(items: previousMenu.items, title: previousMenu.title)
    }
    
    private func getCurrentMenuTitle() -> String {
        switch menuMode {
        case .menu(_, _, let title):
            return title
        case .normal:
            return ""
        }
    }
    
    
    private func exitMenu() {
        menuMode = .normal
        menuStack = [] // Clear menu stack when exiting
        
        // Hide menu and restore normal input
        guard let webView = webView else { return }
        let script = "hideMenu();"
        webView.evaluateJavaScript(script, completionHandler: nil)
        
        showPrompt()
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
