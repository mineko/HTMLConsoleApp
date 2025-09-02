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
                    color: #ffffff;
                    margin-right: 5px;
                    flex-shrink: 0;
                    margin-top: 2px;
                }
                
                #input {
                    background: transparent;
                    border: none;
                    outline: none;
                    color: #ffffff;
                    font-family: inherit;
                    font-size: inherit;
                    flex-grow: 1;
                    caret-color: #ffffff;
                    resize: none;
                    overflow: hidden;
                    min-height: 1.4em;
                    line-height: 1.4;
                    word-wrap: break-word;
                }
                
                .output-line {
                    margin-bottom: 2px;
                }
                
                .new-output {
                    color: #ffffff;
                }
                
                .old-output {
                    color: #00ff00;
                }
            </style>
        </head>
        <body>
            <div id="output"></div>
            <div id="input-line" style="display: none;">
                <span id="prompt">></span>
                <textarea id="input" rows="1"></textarea>
            </div>
            
            <script>
                const output = document.getElementById('output');
                const input = document.getElementById('input');
                
                function addOutput(text, className = '') {
                    const line = document.createElement('div');
                    line.className = 'output-line new-output ' + className;
                    line.textContent = text;
                    output.appendChild(line);
                    scrollToBottom();
                }
                
                function markAllOutputAsOld() {
                    // Change all existing output from new-output to old-output
                    const allOutputLines = output.querySelectorAll('.output-line');
                    allOutputLines.forEach(line => {
                        line.classList.remove('new-output');
                        line.classList.add('old-output');
                    });
                }
                
                function scrollToBottom() {
                    window.scrollTo(0, document.body.scrollHeight);
                }
                
                function autoResizeTextarea() {
                    input.style.height = 'auto';
                    input.style.height = input.scrollHeight + 'px';
                    scrollToBottom();
                }
                
                function showPrompt() {
                    const inputLine = document.getElementById('input-line');
                    inputLine.style.display = 'flex';
                    input.focus();
                    scrollToBottom();
                }
                
                function hidePrompt() {
                    const inputLine = document.getElementById('input-line');
                    inputLine.style.display = 'none';
                }
                
                input.addEventListener('input', autoResizeTextarea);
                
                input.addEventListener('keydown', function(e) {
                    if (e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault(); // Prevent new line
                        const userText = input.value;
                        if (userText.trim()) {
                            // Mark all existing output as old (green) before processing new input
                            markAllOutputAsOld();
                            // Send input to Swift controller for processing
                            window.webkit.messageHandlers.consoleInput.postMessage(userText);
                        }
                        input.value = '';
                        input.style.height = 'auto';
                        input.style.height = '1.4em';
                    }
                });
                
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
