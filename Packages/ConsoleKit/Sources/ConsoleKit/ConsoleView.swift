//
//  ConsoleView.swift
//  ConsoleKit
//

import SwiftUI
import WebKit

/// A SwiftUI view that hosts the HTML console. Drop this into any window or pane.
public struct ConsoleView: View {
    public init() {}

    public var body: some View {
        WebViewRepresentable()
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

class LayoutStateHandler: NSObject, WKScriptMessageHandler {
    let controller: ConsoleController

    init(controller: ConsoleController) {
        self.controller = controller
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "layoutState", let json = message.body as? String else { return }
        controller.updateLayoutState(from: json)
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
    @StateObject private var consoleController = ConsoleController()

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
        let layoutStateHandler = LayoutStateHandler(controller: consoleController)
        configuration.userContentController.add(inputHandler, name: "consoleInput")
        configuration.userContentController.add(menuHandler, name: "menuAction")
        configuration.userContentController.add(consoleLogHandler, name: "consoleLog")
        configuration.userContentController.add(layoutStateHandler, name: "layoutState")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        consoleController.setWebView(webView)
        webView.navigationDelegate = context.coordinator

        guard let htmlURL = consoleController.getHTMLFileURL() else {
            print("Could not find console.html in ConsoleKit bundle")
            return webView
        }

        // Grant read access to the entire app bundle so WebKit can reach
        // both ConsoleKit resources (HTML, CSS) and module resources (images).
        let bundleURL = Bundle.main.bundleURL
        webView.loadFileURL(htmlURL, allowingReadAccessTo: bundleURL)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
