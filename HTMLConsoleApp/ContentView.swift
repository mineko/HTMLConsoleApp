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
            let output = controller.processInput(input)
            controller.addOutput(output)
        }
    }
}

struct WebViewRepresentable: NSViewRepresentable {
    @StateObject private var consoleController = HTMLConsoleController()
    
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
        
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
                    font-size: 14px;
                    background-color: #000000;
                    color: #00ff00;
                    margin: 0;
                    padding: 20px;
                    overflow-wrap: break-word;
                    line-height: 1.4;
                }
                
                #output {
                    white-space: pre-wrap;
                    user-select: text;
                    -webkit-user-select: text;
                }
                
                #input-line {
                    display: flex;
                    align-items: flex-start;
                }
                
                #prompt {
                    color: #00ff00;
                    margin-right: 5px;
                    flex-shrink: 0;
                    margin-top: 2px;
                }
                
                #input {
                    background: transparent;
                    border: none;
                    outline: none;
                    color: #00ff00;
                    font-family: inherit;
                    font-size: inherit;
                    flex-grow: 1;
                    caret-color: #00ff00;
                    resize: none;
                    overflow: hidden;
                    min-height: 1.4em;
                    line-height: 1.4;
                    word-wrap: break-word;
                }
                
                .output-line {
                    margin-bottom: 2px;
                }
                
                .user-input {
                    color: #ffffff;
                }
            </style>
        </head>
        <body>
            <div id="output"></div>
            <div id="input-line">
                <span id="prompt">></span>
                <textarea id="input" rows="1" autofocus></textarea>
            </div>
            
            <script>
                const output = document.getElementById('output');
                const input = document.getElementById('input');
                
                function addOutput(text, className = '') {
                    const line = document.createElement('div');
                    line.className = 'output-line ' + className;
                    line.textContent = text;
                    output.appendChild(line);
                    scrollToBottom();
                }
                
                function scrollToBottom() {
                    window.scrollTo(0, document.body.scrollHeight);
                }
                
                function autoResizeTextarea() {
                    input.style.height = 'auto';
                    input.style.height = input.scrollHeight + 'px';
                    scrollToBottom();
                }
                
                input.addEventListener('input', autoResizeTextarea);
                
                input.addEventListener('keydown', function(e) {
                    if (e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault(); // Prevent new line
                        const userText = input.value;
                        if (userText.trim()) {
                            // Add user input to output
                            //addOutput('> ' + userText, 'user-input');
                            // Send input to Swift controller for processing
                            window.webkit.messageHandlers.consoleInput.postMessage(userText);
                        }
                        input.value = '';
                        input.style.height = 'auto';
                        input.style.height = '1.4em';
                    }
                });
                
                // Initial welcome message
                addOutput('Welcome to HTMLConsole');
                addOutput('Type something and press Enter...');
                
                // Focus input when page loads
                window.addEventListener('load', function() {
                    input.focus();
                });
                
                // Maintain focus on input
                document.addEventListener('click', function() {
                    input.focus();
                });
            </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlString, baseURL: URL(string: "about:blank"))
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No updates needed for now
    }
}

#Preview {
    ContentView()
}
