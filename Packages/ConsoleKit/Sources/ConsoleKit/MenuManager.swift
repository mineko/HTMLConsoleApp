//
//  MenuManager.swift
//  ConsoleKit
//

import Foundation

// Menu navigation result
enum MenuNavigationResult {
    case menu(Menu)
    case action(() -> Void)
}

// Menu item types
enum MenuItemType {
    case submenu(Menu)
    case action(() -> Void)
    case separator
}

struct MenuItem {
    let id: String
    let title: String
    let type: MenuItemType

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

    func execute(controller: ConsoleController) {
        switch type {
        case .submenu(let menu):
            controller.showSubmenu(menu)
        case .action(let action):
            action()
        case .separator:
            break
        }
    }
}

struct Menu {
    let items: [MenuItem]
    let title: String

    var isEmpty: Bool { items.isEmpty }

    func findItem(withTitle title: String) -> MenuItem? {
        return items.first { $0.title.lowercased() == title.lowercased() && !$0.title.isEmpty }
    }

    func navigate(to pathComponents: [String], buildingStack stack: inout [Menu]) -> MenuNavigationResult? {
        var currentMenu = self

        for (index, component) in pathComponents.enumerated() {
            guard let menuItem = currentMenu.findItem(withTitle: component) else {
                return nil
            }

            let isLastComponent = (index == pathComponents.count - 1)

            switch menuItem.type {
            case .submenu(let nextMenu):
                if isLastComponent {
                    stack.append(currentMenu)
                    return .menu(nextMenu)
                } else {
                    stack.append(currentMenu)
                    currentMenu = nextMenu
                }
            case .action(let action):
                if isLastComponent {
                    return .action(action)
                } else {
                    return nil
                }
            case .separator:
                return nil
            }
        }

        return .menu(currentMenu)
    }

    static func createMenu(
        title: String,
        submenus: [(title: String, menu: Menu)] = [],
        actions: [(title: String, action: () -> Void)] = [],
        includeBack: Bool = false,
        includeCancel: Bool = false,
        menuManager: MenuManager? = nil
    ) -> Menu {
        var items: [MenuItem] = []

        for (title, submenu) in submenus {
            items.append(MenuItem(id: "submenu_\(title.lowercased())", title: title, submenu: submenu))
        }

        for (title, action) in actions {
            items.append(MenuItem(id: "action_\(title.lowercased())", title: title, action: action))
        }

        if !items.isEmpty && (includeBack || includeCancel) {
            items.append(MenuItem(id: "separator", title: ""))
        }

        if includeBack, let menuManager = menuManager {
            items.append(MenuItem(id: "back", title: "Back", action: { [weak menuManager] in
                menuManager?.goBack()
            }))
        }

        if includeCancel, let menuManager = menuManager {
            items.append(MenuItem(id: "cancel", title: "Cancel", action: { [weak menuManager] in
                menuManager?.exitMenu()
            }))
        }

        return Menu(items: items, title: title)
    }

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
        self.rootMenu = MenuManager.createMenuHierarchy(menuManager: self)
    }

    private static func createMenuHierarchy(menuManager: MenuManager) -> Menu {
        let themes = menuManager.controller?.getAvailableThemes() ?? []
        let themeActions = themes.map { theme in
            (title: theme, action: { [weak menuManager] in
                menuManager?.controller?.switchTheme(to: theme)
                menuManager?.exitMenu()
            })
        }

        let themeMenu = Menu.createActionMenu(
            title: "Theme",
            actions: themeActions,
            menuManager: menuManager
        )

        let adminActions = [
            ("Toggle Status Bar", { [weak menuManager] in
                if let statusBar = menuManager?.controller?.getStatusBar() {
                    statusBar.toggle()
                }
                menuManager?.exitMenu()
            })
        ]

        let adminMenu = Menu.createMenu(
            title: "Admin",
            submenus: [("Theme", themeMenu)],
            actions: adminActions,
            includeBack: true,
            menuManager: menuManager
        )

        return Menu.createMenu(
            title: "/",
            submenus: [("Admin", adminMenu)],
            includeCancel: true,
            menuManager: menuManager
        )
    }

    func showRootMenu() {
        currentMenu = rootMenu
        menuStack = []
        sendMenuToController(menu: rootMenu)
    }

    func navigateToPath(_ path: String) -> Bool {
        let components = path.split(separator: "/").map(String.init)

        var menuStack: [Menu] = []
        guard let result = rootMenu.navigate(to: components, buildingStack: &menuStack) else {
            return false
        }

        switch result {
        case .menu(let targetMenu):
            self.currentMenu = targetMenu
            self.menuStack = menuStack
            sendMenuToController(menu: targetMenu)
        case .action(let action):
            action()
        }

        return true
    }

    func selectItem(at index: Int) {
        guard let menu = currentMenu,
              index >= 0 && index < menu.items.count else { return }

        let selectedItem = menu.items[index]
        selectedItem.execute(controller: controller!)
    }

    func showSubmenu(_ submenu: Menu) {
        if let menu = currentMenu {
            menuStack.append(menu)
        }
        currentMenu = submenu
        sendMenuToController(menu: submenu)
    }

    func goBack() {
        guard !menuStack.isEmpty else {
            exitMenu()
            return
        }
        let previousMenu = menuStack.removeLast()
        currentMenu = previousMenu
        sendMenuToController(menu: previousMenu)
    }

    func exitMenu() {
        currentMenu = nil
        menuStack = []
        controller?.hideMenu()
    }

    func buildMenuPath() -> String {
        var path = ""
        for menu in menuStack {
            if path.isEmpty {
                path = menu.title
            } else {
                if !path.hasSuffix("/") { path += "/" }
                path += menu.title
            }
        }
        if let currentMenu = currentMenu {
            if path.isEmpty {
                path = currentMenu.title
            } else {
                if !path.hasSuffix("/") { path += "/" }
                path += currentMenu.title
            }
        }
        return path
    }

    var isInMenuMode: Bool {
        return currentMenu != nil
    }

    private func sendMenuToController(menu: Menu) {
        controller?.displayMenu(items: menu.items, title: buildMenuPath())
    }
}
