//
//  ContentView.swift
//  HTMLConsoleApp
//
//  Created by Collin Pieper on 9/1/25.
//

import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        WebViewRepresentable()
            .ignoresSafeArea()
    }
}

// Script message handler to receive messages from JavaScript
class ConsoleMessageHandler: NSObject, WKScriptMessageHandler {
    let controller: HTMLConsoleController
    
    init(controller: HTMLConsoleController) {
        self.controller = controller
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "consoleInput", let input = message.body as? String {
            controller.hidePrompt()
            let output = controller.processInput(input)
            controller.addOutput(output)
            controller.showPrompt()
        }
    }
}


struct WebViewRepresentable: NSViewRepresentable {
    @StateObject private var consoleController = HTMLConsoleController()
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let consoleController: HTMLConsoleController
        
        init(consoleController: HTMLConsoleController) {
            self.consoleController = consoleController
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("Navigation finished - calling start()")
            consoleController.start()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(consoleController: consoleController)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Configure for offline use only - no network requests
        configuration.websiteDataStore = .nonPersistent()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        // Add script message handler for console input
        let messageHandler = ConsoleMessageHandler(controller: consoleController)
        configuration.userContentController.add(messageHandler, name: "consoleInput")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        consoleController.setWebView(webView)
        
        // Set navigation delegate using coordinator
        webView.navigationDelegate = context.coordinator
        
        guard let htmlURL = consoleController.getHTMLFileURL() else {
            print("Could not find console.html in bundle")
            return webView
        }
        
        // Allow read access to the entire bundle directory so CSS files can be loaded
        let bundleURL = Bundle.main.bundleURL
        webView.loadFileURL(htmlURL, allowingReadAccessTo: bundleURL)
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No updates needed for now
    }
}

#Preview {
    ContentView()
}
