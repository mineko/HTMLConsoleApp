//
//  Engine.swift
//  PressKit
//

import Foundation

/// Base class for console engines. Modules subclass this to provide
/// interactive behavior (text adventures, RPGs, etc.).
open class Engine {
    public private(set) weak var controller: ConsoleController?
    public private(set) var statusBar: StatusBar?

    public init(controller: ConsoleController) {
        self.controller = controller
        self.statusBar = controller.getStatusBar()
        configureStatusBar()
    }

    // MARK: - Override Points

    /// Called once the WebView has finished loading. Show your welcome message,
    /// configure the status bar, and call controller?.showPrompt() (optionally
    /// passing a prompt string; defaults to ">").
    open func start() {}

    /// Called when the user submits a line of text (that isn't a menu command).
    open func processInput(_ input: String) {}

    /// Called during init. Override to register status bar fields.
    open func configureStatusBar() {}

    /// Override to provide menu items for the / menu.
    /// Return MenuItem instances with actions or submenus.
    open func menuItems() -> [MenuItem] {
        return []
    }

    // MARK: - Helpers for Subclasses

    public func addOutput(_ text: String) {
        controller?.addOutput(text)
    }

    public func appendOutput(_ text: String) {
        controller?.appendOutput(text)
    }

    public func addContent(text: String = "", image: String = "", caption: String = "", priority: CGFloat = 0.5, imageWidth: Int = 0, imageHeight: Int = 0) {
        controller?.addContent(text: text, image: image, caption: caption, priority: priority, imageWidth: imageWidth, imageHeight: imageHeight)
    }

    public func setLayoutKnob(_ name: String, value: CGFloat) {
        controller?.setLayoutKnob(name, value: value)
    }

    public func getLayoutKnobs() -> LayoutKnobs? {
        return controller?.getLayoutKnobs()
    }

    public func clearOutput() {
        controller?.clearOutput()
    }
}
