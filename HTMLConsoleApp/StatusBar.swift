//
//  StatusBar.swift
//  HTMLConsoleApp
//
//  Created by Claude on 9/7/25.
//

import Foundation
import WebKit

// Status bar text region alignment
enum StatusAlignment {
    case left
    case center
    case right
}

// Individual text region within a status line
struct StatusRegion {
    let text: String
    let alignment: StatusAlignment
    
    init(_ text: String, alignment: StatusAlignment = .left) {
        self.text = text
        self.alignment = alignment
    }
}

// A single line in the status bar with multiple text regions
struct StatusLine {
    let regions: [StatusRegion]
    
    init(_ regions: StatusRegion...) {
        self.regions = Array(regions)
    }
    
    init(regions: [StatusRegion]) {
        self.regions = regions
    }
    
    // Convenience initializers for common patterns
    static func simple(_ text: String, alignment: StatusAlignment = .left) -> StatusLine {
        return StatusLine(StatusRegion(text, alignment: alignment))
    }
    
    static func leftRight(left: String, right: String) -> StatusLine {
        return StatusLine(
            StatusRegion(left, alignment: .left),
            StatusRegion(right, alignment: .right)
        )
    }
    
    static func leftCenterRight(left: String, center: String, right: String) -> StatusLine {
        return StatusLine(
            StatusRegion(left, alignment: .left),
            StatusRegion(center, alignment: .center),
            StatusRegion(right, alignment: .right)
        )
    }
}

// Main status bar class
class StatusBar {
    private var lines: [StatusLine] = []
    private var isVisible: Bool = false
    private weak var controller: ConsoleController?
    
    init(controller: ConsoleController) {
        self.controller = controller
    }
    
    // Set the status bar content
    func setLines(_ lines: [StatusLine]) {
        self.lines = lines
        if isVisible {
            updateDisplay()
        }
    }
    
    // Convenience method for single line
    func setLine(_ line: StatusLine) {
        setLines([line])
    }
    
    // Show the status bar
    func show() {
        isVisible = true
        updateDisplay()
    }
    
    // Hide the status bar
    func hide() {
        isVisible = false
        controller?.hideStatusBar()
    }
    
    // Toggle visibility
    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
    
    // Update a specific line (0-indexed)
    func updateLine(at index: Int, with line: StatusLine) {
        guard index >= 0 else { return }
        
        // Expand lines array if necessary
        while lines.count <= index {
            lines.append(StatusLine.simple(""))
        }
        
        lines[index] = line
        
        if isVisible {
            updateDisplay()
        }
    }
    
    // Add a line at the end
    func addLine(_ line: StatusLine) {
        lines.append(line)
        if isVisible {
            updateDisplay()
        }
    }
    
    // Remove all lines
    func clear() {
        lines.removeAll()
        if isVisible {
            updateDisplay()
        }
    }
    
    // Send current status to the controller for display
    private func updateDisplay() {
        guard isVisible else { return }
        controller?.displayStatusBar(lines: lines)
    }
}