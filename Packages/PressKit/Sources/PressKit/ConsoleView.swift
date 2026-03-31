//
//  ConsoleView.swift
//  PressKit
//

import SwiftUI
import WebKit

/// A SwiftUI view that hosts the HTML console. Drop this into any window or pane.
public struct ConsoleView: View {
    private let module: String
    private let configuration: Any?
    private let theme: String?

    public init(module: String, configuration: Any? = nil, theme: String? = nil) {
        self.module = module
        self.configuration = configuration
        self.theme = theme
    }

    public var body: some View {
        WebViewRepresentable(module: module, configuration: configuration, theme: theme)
            .ignoresSafeArea()
    }
}

// MARK: - Script Message Handlers

class ConsoleInputHandler: NSObject, WKScriptMessageHandler {
    let controller: ConsoleController

    init(controller: ConsoleController) {
        self.controller = controller
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "consoleInput", let input = message.body as? String else { return }
        controller.hidePrompt()
        controller.processInput(input)
    }
}

class ConsoleLogHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "consoleLog", let logMessage = message.body as? String else { return }
        print("[JS] \(logMessage)")
    }
}

class MenuActionHandler: NSObject, WKScriptMessageHandler {
    let controller: ConsoleController

    init(controller: ConsoleController) {
        self.controller = controller
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "menuAction", let action = message.body as? String else { return }
        controller.handleMenuAction(action)
    }
}

// MARK: - WebView Wrapper

struct WebViewRepresentable: NSViewRepresentable {
    let module: String
    let configuration: Any?

    @StateObject private var consoleController: ConsoleController

    init(module: String, configuration: Any? = nil, theme: String? = nil) {
        self.module = module
        self.configuration = configuration
        _consoleController = StateObject(wrappedValue: ConsoleController(module: module, configuration: configuration, theme: theme))
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let consoleController: ConsoleController

        init(consoleController: ConsoleController) {
            self.consoleController = consoleController
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            consoleController.start()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(consoleController: consoleController)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        let inputHandler = ConsoleInputHandler(controller: consoleController)
        let menuHandler = MenuActionHandler(controller: consoleController)
        let consoleLogHandler = ConsoleLogHandler()
        configuration.userContentController.add(inputHandler, name: "consoleInput")
        configuration.userContentController.add(menuHandler, name: "menuAction")
        configuration.userContentController.add(consoleLogHandler, name: "consoleLog")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        consoleController.setWebView(webView)
        webView.navigationDelegate = context.coordinator

        guard let htmlURL = consoleController.getHTMLFileURL() else {
            print("Could not find console.html in PressKit bundle")
            return webView
        }

        // Grant read access to a directory that covers both PressKit resources
        // and external resource paths (e.g. bundle themes with image assets).
        var accessPath = htmlURL.deletingLastPathComponent().path
        for path in consoleController.getResourcePaths() {
            accessPath = Self.commonAncestor(accessPath, path)
        }
        webView.loadFileURL(htmlURL, allowingReadAccessTo: URL(fileURLWithPath: accessPath))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    private static func commonAncestor(_ a: String, _ b: String) -> String {
        let aComponents = a.split(separator: "/", omittingEmptySubsequences: false)
        let bComponents = b.split(separator: "/", omittingEmptySubsequences: false)
        var common: [Substring] = []
        for (ac, bc) in zip(aComponents, bComponents) {
            if ac == bc { common.append(ac) } else { break }
        }
        let result = common.joined(separator: "/")
        return result.isEmpty ? "/" : String(result)
    }
}
