//
//  HTMLConsoleController.swift
//  HTMLConsoleApp
//
//  Created by Collin Pieper on 9/1/25.
//

import Foundation
import WebKit

// Console controller to handle input/output logic
class HTMLConsoleController: NSObject, ObservableObject {
    private weak var webView: WKWebView?
    private let availableThemes = ["Default", "Retro", "Dark", "Light"]
    private var currentTheme: String
    
    override init() {
        // Pick a random theme at initialization
        self.currentTheme = availableThemes.randomElement() ?? "retro"
        super.init()
    }
    
    func getHTMLFileURL() -> URL? {
        return Bundle.main.url(forResource: "console", withExtension: "html")
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
        print("start")
        // Apply the randomly selected theme after webview loads
        switchTheme(to: currentTheme)
        showWelcomeMessage()
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
    
    func processInput(_ input: String) -> String {
        // For now, just echo the input back
        // This is where you can add more sophisticated command processing later
        return input
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
