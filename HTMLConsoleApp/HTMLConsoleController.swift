//
//  HTMLConsoleController.swift
//  HTMLConsoleApp
//
//  Created by Collin Pieper on 9/1/25.
//

import Foundation
import WebKit

// Menu system data structures
enum MenuItemType {
    case submenu(Menu)
    case action(() -> Void)
    case separator  // For spacing items with no behavior
}

struct MenuItem {
    let id: String
    let title: String
    let type: MenuItemType
    
    // Convenience initializers
    init(id: String, title: String, submenu: Menu) {
        self.id = id
        self.title = title
        self.type = .submenu(submenu)
    }
    
    init(id: String, title: String, action: @escaping () -> Void) {
        self.id = id
        self.title = title
        self.type = .action(action)
    }
    
    init(id: String, title: String) {
        self.id = id
        self.title = title
        self.type = .separator
    }
    
    // Execute the menu item's behavior
    func execute(controller: HTMLConsoleController) {
        switch type {
        case .submenu(let menu):
            controller.showSubmenu(menu)
        case .action(let action):
            action()
        case .separator:
            // Do nothing for separators
            break
        }
    }
}

struct Menu {
    let items: [MenuItem]
    let title: String
    
    var isEmpty: Bool {
        return items.isEmpty
    }
    
    // Find a menu item by title (case-insensitive)
    func findItem(withTitle title: String) -> MenuItem? {
        return items.first { item in
            item.title.lowercased() == title.lowercased() && !item.title.isEmpty
        }
    }
    
    // Navigate to a submenu by path components
    func navigate(to pathComponents: [String], buildingStack stack: inout [Menu]) -> Menu? {
        var currentMenu = self
        
        for component in pathComponents {
            // Find the menu item with matching title
            guard let menuItem = currentMenu.findItem(withTitle: component) else {
                return nil // Path component not found
            }
            
            // Check if this menu item has a submenu
            guard case .submenu(let nextMenu) = menuItem.type else {
                return nil // Menu item doesn't lead to a submenu
            }
            
            // Add current menu to stack before moving to next
            stack.append(currentMenu)
            currentMenu = nextMenu
        }
        
        return currentMenu
    }
    
    // Factory method to create a theme selection menu
    static func createThemeMenu(with themes: [String], controller: HTMLConsoleController) -> Menu {
        let themeItems = themes.map { theme in
            MenuItem(id: "theme_\(theme)", title: theme, action: { [weak controller] in
                controller?.switchTheme(to: theme)
                controller?.exitMenu()
            })
        }
        
        let menuItems = themeItems + [
            MenuItem(id: "separator", title: ""), // Empty item for spacing
            MenuItem(id: "back", title: "Back", action: { [weak controller] in
                controller?.goBackInMenu()
            })
        ]
        
        return Menu(items: menuItems, title: "Theme")
    }
    
    // Factory method to create the admin menu
    static func createAdminMenu(themeMenu: Menu, controller: HTMLConsoleController) -> Menu {
        return Menu(items: [
            MenuItem(id: "theme_menu", title: "Theme", submenu: themeMenu),
            MenuItem(id: "separator", title: ""), // Empty item for spacing
            MenuItem(id: "back", title: "Back", action: { [weak controller] in
                controller?.goBackInMenu()
            })
        ], title: "Admin")
    }
    
    // Factory method to create the root menu
    static func createRootMenu(adminMenu: Menu, controller: HTMLConsoleController) -> Menu {
        return Menu(items: [
            MenuItem(id: "admin_menu", title: "Admin", submenu: adminMenu),
            MenuItem(id: "separator", title: ""), // Empty item for spacing
            MenuItem(id: "cancel", title: "Cancel", action: { [weak controller] in
                controller?.exitMenu()
            })
        ], title: "/")
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
        } else if input.hasPrefix("/") {
            // Try to navigate to a menu path
            if navigateToMenuPath(input) {
                // Successfully navigated to menu path
                return
            } else {
                // Path not found, show error and continue with normal processing
                addOutput("Menu path not found: \(input)")
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
        let themeMenu = Menu.createThemeMenu(with: availableThemes, controller: self)
        let adminMenu = Menu.createAdminMenu(themeMenu: themeMenu, controller: self)
        rootMenu = Menu.createRootMenu(adminMenu: adminMenu, controller: self)
    }
    
    private func showRootMenu() {
        currentMenu = rootMenu
        menuStack = [] // Clear menu stack for root menu
        sendMenuToJS(items: rootMenu.items, title: buildMenuPath())
    }
    
    internal func showSubmenu(_ submenu: Menu?) {
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
    
    private func navigateToMenuPath(_ path: String) -> Bool {
        // Split the path into components
        let components = path.split(separator: "/").map(String.init)
        
        // Use the menu's navigation method
        var menuStack: [Menu] = []
        guard let targetMenu = rootMenu.navigate(to: components, buildingStack: &menuStack) else {
            return false // Path not found
        }
        
        // Set the current menu and stack
        self.currentMenu = targetMenu
        self.menuStack = menuStack
        sendMenuToJS(items: targetMenu.items, title: buildMenuPath())
        return true
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
        selectedItem.execute(controller: self)
    }
    
    
    internal func goBackInMenu() {
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
    
    
    internal func exitMenu() {
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
