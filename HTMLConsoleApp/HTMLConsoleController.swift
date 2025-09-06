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
    let action: () -> Void
}

struct Menu {
    let items: [MenuItem]
    let title: String
    
    var isEmpty: Bool {
        return items.isEmpty
    }
}

// Console controller to handle input/output logic
class HTMLConsoleController: NSObject, ObservableObject {
    private weak var webView: WKWebView?
    private var availableThemes: [String] = []
    private var currentTheme: String
    private var currentMenu: Menu? = nil
    private var menuStack: [Menu] = []
    private var rootMenu: Menu!
    
    override init() {
        // Initialize with placeholder values
        self.availableThemes = []
        self.currentTheme = "default"
        super.init()
        
        // Dynamically discover CSS files in the bundle after super.init()
        self.availableThemes = self.discoverAvailableThemes()
        // Pick a random theme at initialization
        self.currentTheme = availableThemes.randomElement() ?? "default"
        
        // Create menus once during initialization
        self.createMenus()
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
        // Only handle normal user input - menu actions are handled separately
        if input == "/" {
            showRootMenu()
        } else {
            // Normal echo functionality
            addOutput("\n" + input)
            showPrompt()
        }
    }
    
    func handleMenuAction(_ action: String) {
        // If no current menu, ignore the action
        guard let menu = currentMenu else { return }
        
        if action.hasPrefix("SELECT:") {
            let indexString = String(action.dropFirst(7)) // Remove "SELECT:" prefix
            if let index = Int(indexString) {
                selectMenuItem(items: menu.items, index: index)
            }
        } else if action == "CANCEL" {
            exitMenu()
        }
    }
    
    private func createMenus() {
        // Create theme menu items
        let themeItems = availableThemes.map { theme in
            MenuItem(id: "theme_\(theme)", title: theme, action: { [weak self] in
                self?.switchTheme(to: theme)
                self?.exitMenu()
            })
        }
        
        // Create theme submenu with Back option
        let themeMenu = Menu(items: createSubmenuWithBack(themeItems), title: "Theme")
        
        // Create admin menu
        let adminMenu = Menu(items: [
            MenuItem(id: "theme_menu", title: "Theme", action: { [weak self] in
                self?.showSubmenu(themeMenu)
            }),
            MenuItem(id: "separator", title: "", action: {}), // Empty item for spacing
            MenuItem(id: "back", title: "Back", action: { [weak self] in
                self?.goBackInMenu()
            })
        ], title: "Admin")
        
        // Create root menu
        rootMenu = Menu(items: [
            MenuItem(id: "admin_menu", title: "Admin", action: { [weak self] in
                self?.showSubmenu(adminMenu)
            }),
            MenuItem(id: "separator", title: "", action: {}), // Empty item for spacing
            MenuItem(id: "cancel", title: "Cancel", action: { [weak self] in
                self?.exitMenu()
            })
        ], title: "/")
    }
    
    private func showRootMenu() {
        currentMenu = rootMenu
        menuStack = [] // Clear menu stack for root menu
        sendMenuToJS(items: rootMenu.items, title: buildMenuPath())
    }
    
    private func showSubmenu(_ submenu: Menu?) {
        guard let submenu = submenu else { return }
        
        // Push current menu to stack before entering submenu
        if let menu = currentMenu {
            menuStack.append(menu)
        }
        
        currentMenu = submenu
        sendMenuToJS(items: submenu.items, title: buildMenuPath())
    }
    
    private func buildMenuPath() -> String {
        var path = ""
        
        // Add all menus from the stack
        for menu in menuStack {
            if path.isEmpty {
                path = menu.title
            } else {
                // Only add "/" if the current path doesn't end with "/"
                if !path.hasSuffix("/") {
                    path += "/"
                }
                path += menu.title
            }
        }
        
        // Add current menu
        if let currentMenu = currentMenu {
            if path.isEmpty {
                path = currentMenu.title
            } else {
                // Only add "/" if the current path doesn't end with "/"
                if !path.hasSuffix("/") {
                    path += "/"
                }
                path += currentMenu.title
            }
        }
        
        return path
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
        selectedItem.action()
    }
    
    private func createSubmenuWithBack(_ items: [MenuItem]) -> [MenuItem] {
        var submenuItems = items
        submenuItems.append(MenuItem(id: "separator", title: "", action: {})) // Empty item for spacing
        submenuItems.append(MenuItem(id: "back", title: "Back", action: { [weak self] in
            self?.goBackInMenu()
        }))
        return submenuItems
    }
    
    private func goBackInMenu() {
        guard !menuStack.isEmpty else {
            exitMenu()
            return
        }
        
        let previousMenu = menuStack.removeLast()
        currentMenu = previousMenu
        sendMenuToJS(items: previousMenu.items, title: buildMenuPath())
    }
    
    private func getCurrentMenuTitle() -> String {
        return currentMenu?.title ?? ""
    }
    
    
    private func exitMenu() {
        currentMenu = nil
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
