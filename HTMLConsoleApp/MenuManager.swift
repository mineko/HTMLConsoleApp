//
//  ConsoleController.swift
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
    func execute(controller: ConsoleController) {
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
    
    // Generic factory method to create a menu with submenus and actions
    static func createMenu(
        title: String,
        submenus: [(title: String, menu: Menu)] = [],
        actions: [(title: String, action: () -> Void)] = [],
        includeBack: Bool = false,
        includeCancel: Bool = false,
        menuManager: MenuManager? = nil
    ) -> Menu {
        var items: [MenuItem] = []
        
        // Add submenu items
        for (title, submenu) in submenus {
            items.append(MenuItem(id: "submenu_\(title.lowercased())", title: title, submenu: submenu))
        }
        
        // Add action items
        for (title, action) in actions {
            items.append(MenuItem(id: "action_\(title.lowercased())", title: title, action: action))
        }
        
        // Add separator before navigation items if we have content items
        if !items.isEmpty && (includeBack || includeCancel) {
            items.append(MenuItem(id: "separator", title: ""))
        }
        
        // Add back button if requested
        if includeBack, let menuManager = menuManager {
            items.append(MenuItem(id: "back", title: "Back", action: { [weak menuManager] in
                menuManager?.goBack()
            }))
        }
        
        // Add cancel button if requested
        if includeCancel, let menuManager = menuManager {
            items.append(MenuItem(id: "cancel", title: "Cancel", action: { [weak menuManager] in
                menuManager?.exitMenu()
            }))
        }
        
        return Menu(items: items, title: title)
    }
    
    // Convenience method to create an action menu (leaf menu with actions)
    static func createActionMenu(
        title: String,
        actions: [(title: String, action: () -> Void)],
        menuManager: MenuManager
    ) -> Menu {
        return createMenu(
            title: title,
            actions: actions,
            includeBack: true,
            menuManager: menuManager
        )
    }
}

// Menu management class
class MenuManager {
    private var currentMenu: Menu?
    private var menuStack: [Menu] = []
    private var rootMenu: Menu!
    private weak var controller: ConsoleController?
    
    init(controller: ConsoleController) {
        self.controller = controller
        // Now we can safely create the menu hierarchy
        self.rootMenu = MenuManager.createMenuHierarchy(menuManager: self)
    }
    
    // Create the complete menu hierarchy
    private static func createMenuHierarchy(menuManager: MenuManager) -> Menu {
        // Get themes from controller
        let themes = menuManager.controller?.getAvailableThemes() ?? []
        // Create theme actions
        let themeActions = themes.map { theme in
            (title: theme, action: { [weak menuManager] in
                menuManager?.controller?.switchTheme(to: theme)
                menuManager?.exitMenu()
            })
        }
        
        // Create theme menu (leaf menu with actions)
        let themeMenu = Menu.createActionMenu(
            title: "Theme",
            actions: themeActions,
            menuManager: menuManager
        )
        
        // Create admin menu (has submenu)
        let adminMenu = Menu.createMenu(
            title: "Admin",
            submenus: [("Theme", themeMenu)],
            includeBack: true,
            menuManager: menuManager
        )
        
        // Create root menu (has submenu and cancel)
        return Menu.createMenu(
            title: "/",
            submenus: [("Admin", adminMenu)],
            includeCancel: true,
            menuManager: menuManager
        )
    }
    
    // Show the root menu
    func showRootMenu() {
        currentMenu = rootMenu
        menuStack = [] // Clear menu stack for root menu
        sendMenuToController(menu: rootMenu)
    }
    
    // Navigate to a menu path
    func navigateToPath(_ path: String) -> Bool {
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
        sendMenuToController(menu: targetMenu)
        return true
    }
    
    // Handle menu item selection
    func selectItem(at index: Int) {
        guard let menu = currentMenu,
              index >= 0 && index < menu.items.count else { return }
        
        let selectedItem = menu.items[index]
        selectedItem.execute(controller: controller!)
    }
    
    // Show a submenu
    func showSubmenu(_ submenu: Menu) {
        // Push current menu to stack before entering submenu
        if let menu = currentMenu {
            menuStack.append(menu)
        }
        
        currentMenu = submenu
        sendMenuToController(menu: submenu)
    }
    
    // Go back in menu hierarchy
    func goBack() {
        guard !menuStack.isEmpty else {
            exitMenu()
            return
        }
        
        let previousMenu = menuStack.removeLast()
        currentMenu = previousMenu
        sendMenuToController(menu: previousMenu)
    }
    
    // Exit menu system
    func exitMenu() {
        currentMenu = nil
        menuStack = [] // Clear menu stack when exiting
        controller?.hideMenu()
    }
    
    // Build the current menu path for display
    func buildMenuPath() -> String {
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
    
    // Check if currently in menu mode
    var isInMenuMode: Bool {
        return currentMenu != nil
    }
    
    // Send menu data to controller for display
    private func sendMenuToController(menu: Menu) {
        controller?.displayMenu(items: menu.items, title: buildMenuPath())
    }
}
