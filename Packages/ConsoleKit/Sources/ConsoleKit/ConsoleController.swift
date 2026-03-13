//
//  ConsoleController.swift
//  ConsoleKit
//

import Foundation
import WebKit

/// Central controller that bridges the WKWebView console UI with the engine.
public class ConsoleController: NSObject, ObservableObject {
    private weak var webView: WKWebView?
    private var availableThemes: [String] = []
    private var currentTheme: String
    private var menuManager: MenuManager!
    private var statusBar: StatusBar?
    private var engine: Engine?

    override public init() {
        self.availableThemes = []
        self.currentTheme = "default"
        super.init()

        self.availableThemes = Self.discoverAvailableThemes()
        self.currentTheme = availableThemes.randomElement() ?? "default"
        self.menuManager = MenuManager(controller: self)
        self.statusBar = StatusBar(controller: self)

        // Create engine from the module registry
        self.engine = ModuleRegistry.shared.createDefaultEngine(controller: self)
        if engine == nil {
            print("ConsoleController: No modules registered in ModuleRegistry")
        }
    }

    // MARK: - Theme Discovery

    private static func discoverAvailableThemes() -> [String] {
        guard let bundlePath = Bundle.module.resourcePath else {
            return ["default"]
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
            let cssFiles = contents
                .filter { $0.hasSuffix(".css") }
                .map { String($0.dropLast(4)) }
                .sorted()
            return cssFiles.isEmpty ? ["default"] : cssFiles
        } catch {
            return ["default"]
        }
    }

    // MARK: - WebView Setup

    func getHTMLFileURL() -> URL? {
        return Bundle.module.url(forResource: "console", withExtension: "html")
    }

    public func setWebView(_ webView: WKWebView) {
        self.webView = webView
    }

    // MARK: - Lifecycle

    public func start() {
        switchTheme(to: currentTheme)
        engine?.start()
    }

    // MARK: - Theme

    func switchTheme(to themeName: String) {
        guard let webView = webView else { return }
        currentTheme = themeName
        // Use absolute file URL so WebKit can find the CSS in the package bundle
        if let themeURL = Bundle.module.url(forResource: themeName, withExtension: "css") {
            let script = "document.querySelector('link[rel=\"stylesheet\"]').href = '\(themeURL.absoluteString)';"
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
    }

    // MARK: - Prompt

    public func showPrompt() {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("showPrompt();", completionHandler: nil)
    }

    func hidePrompt() {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("hidePrompt();", completionHandler: nil)
    }

    // MARK: - Input Processing

    func processInput(_ input: String) {
        if input == "/" {
            menuManager.showRootMenu()
        } else if input.hasPrefix("/") {
            if menuManager.navigateToPath(input) {
                return
            } else {
                showError("Menu path not found: \(input)")
                showPrompt()
                return
            }
        } else {
            engine?.processInput(input)
        }
    }

    func handleMenuAction(_ action: String) {
        guard menuManager.isInMenuMode else { return }

        if action.hasPrefix("SELECT:") {
            let indexString = String(action.dropFirst(7))
            if let index = Int(indexString) {
                menuManager.selectItem(at: index)
            }
        } else if action == "CANCEL" {
            menuManager.exitMenu()
        }
    }

    // MARK: - Menu Interface (internal, used by MenuManager)

    internal func getAvailableThemes() -> [String] {
        return availableThemes
    }

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

    internal func displayMenu(items: [MenuItem], title: String) {
        guard let webView = webView else { return }

        let itemTitles = items.map { $0.title }
        let itemsJSON = try! JSONSerialization.data(withJSONObject: itemTitles, options: [])
        let itemsString = String(data: itemsJSON, encoding: .utf8)!

        let escapedTitle = title.replacingOccurrences(of: "'", with: "\\'")
        let script = "showMenu({title: '\(escapedTitle)', items: \(itemsString)});"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    internal func hideMenu() {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("hideMenu();", completionHandler: nil)
        showPrompt()
    }

    // MARK: - Error Display

    private func showError(_ message: String) {
        guard let webView = webView else { return }
        let escapedMessage = message.replacingOccurrences(of: "\\", with: "\\\\")
                                    .replacingOccurrences(of: "'", with: "\\'")
        webView.evaluateJavaScript("showError('\(escapedMessage)');", completionHandler: nil)
    }

    // MARK: - Output (public, used by Engine subclasses)

    public func addOutput(_ text: String) {
        guard let webView = webView else { return }
        let escapedText = text.replacingOccurrences(of: "\\", with: "\\\\")
                             .replacingOccurrences(of: "'", with: "\\'")
                             .replacingOccurrences(of: "\n", with: "\\n")
        webView.evaluateJavaScript("addOutput('\(escapedText)');", completionHandler: nil)
    }

    public func addContent(text: String = "", image: String = "", caption: String = "") {
        guard let webView = webView else { return }
        let escapedText = text.replacingOccurrences(of: "\\", with: "\\\\")
                             .replacingOccurrences(of: "'", with: "\\'")
                             .replacingOccurrences(of: "\n", with: "\\n")
        let escapedImage = image.replacingOccurrences(of: "\\", with: "\\\\")
                               .replacingOccurrences(of: "'", with: "\\'")
        let escapedCaption = caption.replacingOccurrences(of: "\\", with: "\\\\")
                                   .replacingOccurrences(of: "'", with: "\\'")
        webView.evaluateJavaScript("addContent('\(escapedText)', '\(escapedImage)', '\(escapedCaption)');", completionHandler: nil)
    }

    // MARK: - Status Bar

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
            webView.evaluateJavaScript("showStatusBar(\(jsonString));", completionHandler: nil)
        } catch {
            print("Error serializing status bar data: \(error)")
        }
    }

    internal func hideStatusBar() {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("hideStatusBar();", completionHandler: nil)
    }

    public func getStatusBar() -> StatusBar? {
        return statusBar
    }

    public func evaluateJavaScript(_ script: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        guard let webView = webView else {
            completionHandler?(nil, NSError(domain: "WebViewError", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "WebView not available"]))
            return
        }
        webView.evaluateJavaScript(script, completionHandler: completionHandler)
    }
}
