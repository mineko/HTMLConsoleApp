//
//  MenuManager.swift
//  PressKit
//

import Foundation

// Menu navigation result
enum MenuNavigationResult {
    case menu(Menu)
    case action(() -> Void)
}

// Menu item types
public enum MenuItemType {
    case submenu(Menu)
    case action(() -> Void)
    case separator
}

public struct MenuItem {
    let id: String
    public let title: String
    public let subtitle: String?
    public let type: MenuItemType

    public init(id: String, title: String, subtitle: String? = nil, submenu: Menu) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.type = .submenu(submenu)
    }

    public init(id: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.type = .action(action)
    }

    public init(id: String, title: String) {
        self.id = id
        self.title = title
        self.subtitle = nil
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

public struct Menu {
    public let items: [MenuItem]
    public let title: String

    public init(items: [MenuItem], title: String) {
        self.items = items
        self.title = title
    }

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

    /// Build a menu from submenus and actions, with optional Back/Cancel items.
    public static func createMenu(
        title: String,
        submenus: [(title: String, menu: Menu)] = [],
        actions: [(title: String, action: () -> Void)] = [],
        extraItems: [MenuItem] = [],
        includeBack: Bool = false,
        includeCancel: Bool = false,
        menuManager: MenuManager? = nil
    ) -> Menu {
        var items: [MenuItem] = []

        for item in extraItems {
            items.append(item)
        }

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

    public static func createActionMenu(
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
public class MenuManager {
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

        let layoutMenu = createLayoutMenu(menuManager: menuManager)

        let adminItems: [MenuItem] = [
            MenuItem(id: "submenu_theme", title: "Theme", subtitle: "Change color theme", submenu: themeMenu),
            MenuItem(id: "submenu_layout", title: "Layout", subtitle: "Adjust layout settings", submenu: layoutMenu),
            MenuItem(id: "action_toggle_status_bar", title: "Toggle Status Bar", subtitle: "Show or hide the status bar", action: { [weak menuManager] in
                if let statusBar = menuManager?.controller?.getStatusBar() {
                    statusBar.toggle()
                }
                menuManager?.exitMenu()
            }),
            MenuItem(id: "separator", title: ""),
            MenuItem(id: "back", title: "Back", action: { [weak menuManager] in
                menuManager?.goBack()
            })
        ]

        let adminMenu = Menu(items: adminItems, title: "Admin")

        // Get engine-provided menu items and wrap actions to auto-exit menu
        let engineItems = (menuManager.controller?.getEngineMenuItems() ?? []).map { item -> MenuItem in
            wrapMenuItem(item, menuManager: menuManager)
        }

        var rootItems: [MenuItem] = engineItems
        rootItems.append(MenuItem(id: "submenu_admin", title: "Admin", subtitle: "Adjust admin options", submenu: adminMenu))
        if !rootItems.isEmpty {
            rootItems.append(MenuItem(id: "separator", title: ""))
            rootItems.append(MenuItem(id: "cancel", title: "Cancel", action: { [weak menuManager] in
                menuManager?.exitMenu()
            }))
        }
        return Menu(items: rootItems, title: "/")
    }

    /// Wrap a MenuItem so actions auto-exit the menu, and submenus get Back buttons.
    private static func wrapMenuItem(_ item: MenuItem, menuManager: MenuManager) -> MenuItem {
        switch item.type {
        case .action(let action):
            return MenuItem(id: item.id, title: item.title, subtitle: item.subtitle, action: { [weak menuManager] in
                action()
                menuManager?.exitMenu()
            })
        case .submenu(let submenu):
            let wrappedChildren = submenu.items.map { wrapMenuItem($0, menuManager: menuManager) }
            var items = wrappedChildren
            if !items.isEmpty {
                items.append(MenuItem(id: "separator", title: ""))
                items.append(MenuItem(id: "back", title: "Back", action: { [weak menuManager] in
                    menuManager?.goBack()
                }))
            }
            let wrappedMenu = Menu(items: items, title: submenu.title)
            return MenuItem(id: item.id, title: item.title, subtitle: item.subtitle, submenu: wrappedMenu)
        case .separator:
            return item
        }
    }

    /// When true, layout knob submenus show the current value in their title
    /// (e.g. "Density (0.4)"). Set to false for clean names only (Option A).
    private static let showKnobValuesInMenuTitles = true

    private static func createLayoutMenu(menuManager: MenuManager) -> Menu {
        let knobs = menuManager.controller?.getLayoutKnobs() ?? LayoutKnobs()

        let knobDefs: [(display: String, key: String, current: CGFloat)] = [
            ("Density", "density", knobs.density),
            ("Prominence", "prominence", knobs.prominence),
            ("Variety", "variety", knobs.variety),
            ("Priority Bias", "priority", knobs.priorityBias),
            ("Text Before Images", "textBefore", knobs.textBefore),
        ]

        let steps: [CGFloat] = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]

        var knobSubmenus: [(title: String, menu: Menu)] = []

        for knob in knobDefs {
            let currentRounded = (knob.current * 10).rounded() / 10
            let actions = steps.map { step in
                let isSelected = abs(step - currentRounded) < 0.05
                let label = isSelected ? "\(String(format: "%.1f", step)) \u{25C0}" : String(format: "%.1f", step)
                return (title: label, action: { [weak menuManager] in
                    menuManager?.controller?.setLayoutKnob(knob.key, value: step)
                    menuManager?.exitMenu()
                })
            }
            let displayTitle = showKnobValuesInMenuTitles
                ? "\(knob.display) (\(String(format: "%.1f", knob.current)))"
                : knob.display
            let submenu = Menu.createActionMenu(
                title: displayTitle,
                actions: actions,
                menuManager: menuManager
            )
            knobSubmenus.append((title: displayTitle, menu: submenu))
        }

        let debugEnabled = menuManager.controller?.layoutDebugEnabled ?? false
        let debugToggleTitle = debugEnabled ? "Layout Debug (On)" : "Layout Debug (Off)"
        let debugAction = (title: debugToggleTitle, action: { [weak menuManager] in
            if let controller = menuManager?.controller {
                controller.setLayoutDebug(!controller.layoutDebugEnabled)
            }
            menuManager?.exitMenu()
        })

        return Menu.createMenu(
            title: "Layout",
            submenus: knobSubmenus,
            actions: [debugAction],
            includeBack: true,
            menuManager: menuManager
        )
    }

    func rebuildMenu() {
        self.rootMenu = MenuManager.createMenuHierarchy(menuManager: self)
    }

    func showRootMenu() {
        // Rebuild so menus reflect current state (knob values, etc.)
        rebuildMenu()
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

    public func goBack() {
        guard !menuStack.isEmpty else {
            exitMenu()
            return
        }
        let previousMenu = menuStack.removeLast()
        currentMenu = previousMenu
        sendMenuToController(menu: previousMenu)
    }

    public func exitMenu() {
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
