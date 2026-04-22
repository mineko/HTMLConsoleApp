//
//  ConsoleController.swift
//  PressKit
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
    private var resourcePaths: [String] = []

    public init(module: String, configuration: Any? = nil, theme: String? = nil) {
        self.availableThemes = []
        self.currentTheme = "default"
        super.init()

        self.menuManager = MenuManager(controller: self)
        self.statusBar = StatusBar(controller: self)

        // Create engine from the module registry
        self.engine = ModuleRegistry.shared.createEngine(named: module, controller: self, configuration: configuration)
        if engine == nil {
            print("ConsoleController: No module registered with name '\(module)'")
        }

        // Collect resource paths: external → module → built-in (highest to lowest priority)
        if let path = engine?.externalBundlePath() { resourcePaths.append(path) }
        if let path = engine?.moduleBundlePath() { resourcePaths.append(path) }
        if let path = Bundle.module.resourcePath { resourcePaths.append(path) }

        self.availableThemes = Self.discoverAvailableThemes(resourcePaths: resourcePaths)
        self.currentTheme = theme ?? availableThemes.randomElement() ?? "default"

        // Rebuild menu now that engine exists (so engine menu actions are included)
        self.menuManager.rebuildMenu()
    }

    // MARK: - Theme Discovery

    private static func discoverAvailableThemes(resourcePaths: [String]) -> [String] {
        var themes: Set<String> = []
        for path in resourcePaths {
            let themesDir = (path as NSString).appendingPathComponent("themes")
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: themesDir) {
                for entry in contents where entry.hasSuffix(".theme") {
                    let cssPath = (themesDir as NSString)
                        .appendingPathComponent(entry)
                        .appending("/theme.css")
                    if FileManager.default.fileExists(atPath: cssPath) {
                        themes.insert(String(entry.dropLast(6))) // drop ".theme"
                    }
                }
            }
        }

        let sorted = themes.sorted()
        return sorted.isEmpty ? ["default"] : sorted
    }

    // MARK: - WebView Setup

    func getHTMLFileURL() -> URL? {
        return Bundle.module.url(forResource: "console", withExtension: "html")
    }

    func getResourcePaths() -> [String] {
        return resourcePaths
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

        guard let themeDir = resolveThemeDir(themeName),
              let css = try? String(contentsOf: themeDir.appendingPathComponent("theme.css"), encoding: .utf8)
        else { return }

        // Resolve relative url() references to absolute file:// URLs so
        // WKWebView can load images regardless of sandbox constraints.
        let resolvedCSS = resolveRelativeURLs(in: css, baseDir: themeDir)

        // Inject as inline <style>, replacing any previous theme style block
        let escaped = resolvedCSS
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
        let script = """
            (function() {
                var existing = document.getElementById('theme-style');
                if (existing) existing.remove();
                var link = document.querySelector('link[rel="stylesheet"]');
                if (link) link.remove();
                var style = document.createElement('style');
                style.id = 'theme-style';
                style.textContent = '\(escaped)';
                document.head.appendChild(style);
            })();
            """
        webView.evaluateJavaScript(script) { _, _ in
            webView.evaluateJavaScript("renderLayout(true); requestAnimationFrame(updateContentPadding);", completionHandler: nil)
        }
    }

    private func resolveThemeDir(_ themeName: String) -> URL? {
        for path in resourcePaths {
            let dir = URL(fileURLWithPath: path).appendingPathComponent("themes/\(themeName).theme")
            if FileManager.default.fileExists(atPath: dir.appendingPathComponent("theme.css").path) {
                return dir
            }
        }
        return nil
    }

    /// Rewrites relative url() references in CSS to absolute file:// URLs.
    private func resolveRelativeURLs(in css: String, baseDir: URL) -> String {
        // Match url('...') or url("...") or url(...)
        let pattern = #"url\(\s*['"]?([^'")]+?)['"]?\s*\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return css }
        let nsCSS = css as NSString
        var result = css
        // Process matches in reverse so ranges stay valid
        let matches = regex.matches(in: css, range: NSRange(location: 0, length: nsCSS.length))
        for match in matches.reversed() {
            guard match.numberOfRanges >= 2 else { continue }
            let relPath = nsCSS.substring(with: match.range(at: 1))
            // Skip data: and absolute URLs
            if relPath.hasPrefix("data:") || relPath.hasPrefix("http") || relPath.hasPrefix("file:") { continue }
            let absURL = baseDir.appendingPathComponent(relPath)
            let replacement = "url('\(absURL.absoluteString)')"
            let range = Range(match.range(at: 0), in: result)!
            result.replaceSubrange(range, with: replacement)
        }
        return result
    }

    // MARK: - Prompt

    public func showPrompt(_ prompt: String? = nil) {
        guard let webView = webView else { return }
        if let prompt = prompt {
            let escaped = escapeForJS(prompt)
            webView.evaluateJavaScript("showPrompt('\(escaped)');", completionHandler: nil)
        } else {
            webView.evaluateJavaScript("showPrompt();", completionHandler: nil)
        }
    }

    func hidePrompt() {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("hidePrompt();", completionHandler: nil)
    }

    // MARK: - Input Processing

    func processInput(_ input: String) {
        // Modal (game-driven) menus swallow everything — the only way out is
        // to pick an item.
        if menuManager.isModal {
            return
        }
        if input == "/" {
            menuManager.showRootMenu()
        } else if input.hasPrefix("/") {
            if menuManager.navigateToPath(input) {
                return
            }
            // Not a known menu path — pass to engine (game handles its own slash commands)
            engine?.processInput(input)
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
            if menuManager.isModal { return }
            menuManager.exitMenu()
        }
    }

    // MARK: - Menu Interface (internal, used by MenuManager)

    internal func getAvailableThemes() -> [String] {
        return availableThemes
    }

    public func rebuildMenu() {
        menuManager.rebuildMenu()
    }

    /// Present a game-driven choice menu. No admin, no Back, no Cancel; the
    /// user can only pick one of the supplied choices. Use a single-choice
    /// list for a "Next" continuation.
    public func presentChoices(title: String, choices: [(title: String, action: () -> Void)]) {
        let items = choices.map { choice in
            MenuItem(id: "choice_\(choice.title.lowercased())", title: choice.title, action: choice.action)
        }
        menuManager.showModalMenu(Menu(items: items, title: title))
    }

    internal func getEngineMenuItems() -> [MenuItem] {
        return engine?.menuItems() ?? []
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

    internal func displayMenu(items: [MenuItem], title: String, modal: Bool = false) {
        guard let webView = webView else { return }

        let itemDicts: [[String: String]] = items.map { item in
            var dict = ["title": item.title]
            if let subtitle = item.subtitle {
                dict["subtitle"] = subtitle
            }
            return dict
        }
        let itemsJSON = try! JSONSerialization.data(withJSONObject: itemDicts, options: [])
        let itemsString = String(data: itemsJSON, encoding: .utf8)!

        let escapedTitle = title.replacingOccurrences(of: "'", with: "\\'")
        let script = "showMenu({title: '\(escapedTitle)', items: \(itemsString), modal: \(modal)});"
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
        let escapedText = escapeForJS(text)
        webView.evaluateJavaScript("addOutput('\(escapedText)');", completionHandler: nil)
    }

    public func appendOutput(_ text: String) {
        guard let webView = webView else { return }
        let escapedText = escapeForJS(text)
        webView.evaluateJavaScript("appendOutput('\(escapedText)');", completionHandler: nil)
    }

    public func addContent(text: String = "", style: String = "", image: String = "", caption: String = "", priority: CGFloat = 0.5, imageWidth: Int = 0, imageHeight: Int = 0) {
        guard let webView = webView else { return }

        // Push text into JS content stream
        if !text.isEmpty {
            let escaped = escapeForJS(text)
            let escapedStyle = escapeForJS(style)
            webView.evaluateJavaScript("pushText('\(escaped)', '\(escapedStyle)');", completionHandler: nil)
        }

        // Push image candidate into JS content stream (JS decides if/how to display it)
        if !image.isEmpty {
            let escapedSrc = escapeForJS(image)
            let escapedCaption = escapeForJS(caption)
            webView.evaluateJavaScript("pushImage('\(escapedSrc)', '\(escapedCaption)', \(priority), \(imageWidth), \(imageHeight));", completionHandler: nil)
        }
    }

    // MARK: - Layout Knobs

    public func setLayoutKnob(_ name: String, value: CGFloat) {
        knobsCache.set(name, value: value)
        guard let webView = webView else { return }
        let escaped = name.replacingOccurrences(of: "'", with: "\\'")
        webView.evaluateJavaScript("setLayoutKnob('\(escaped)', \(value));", completionHandler: nil)
    }

    public func getLayoutKnobs() -> LayoutKnobs {
        // Knobs now live in JS; return a snapshot
        // For synchronous access, maintain a Swift-side copy
        return knobsCache
    }

    public private(set) var layoutDebugEnabled = false

    public func setLayoutDebug(_ enabled: Bool) {
        layoutDebugEnabled = enabled
        guard let webView = webView else { return }
        webView.evaluateJavaScript("setLayoutDebug(\(enabled ? "true" : "false"));", completionHandler: nil)
    }

    public func clearOutput() {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("clearOutput();", completionHandler: nil)
    }

    private var knobsCache = LayoutKnobs()

    public func syncKnobs() {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("getLayoutKnobs();") { [weak self] result, _ in
            guard let self = self, let json = result as? String,
                  let data = json.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Double] else { return }
            if let v = dict["density"] { self.knobsCache.density = CGFloat(v) }
            if let v = dict["prominence"] { self.knobsCache.prominence = CGFloat(v) }
            if let v = dict["variety"] { self.knobsCache.variety = CGFloat(v) }
            if let v = dict["priorityBias"] { self.knobsCache.priorityBias = CGFloat(v) }
            if let v = dict["textBefore"] { self.knobsCache.textBefore = CGFloat(v) }
        }
    }

    private func escapeForJS(_ str: String) -> String {
        return str.replacingOccurrences(of: "\\", with: "\\\\")
                  .replacingOccurrences(of: "'", with: "\\'")
                  .replacingOccurrences(of: "\n", with: "\\n")
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

    public func evaluateJavaScript(_ script: String, completionHandler: (@Sendable (Any?, Error?) -> Void)? = nil) {
        guard let webView = webView else {
            completionHandler?(nil, NSError(domain: "WebViewError", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "WebView not available"]))
            return
        }
        webView.evaluateJavaScript(script, completionHandler: completionHandler)
    }
}
