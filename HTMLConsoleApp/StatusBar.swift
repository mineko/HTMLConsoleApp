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
    private var maxLines: Int = 2 // Default to 2 lines
    private var fieldNames: [String: (line: Int, alignment: StatusAlignment)] = [:] // Custom field naming
    
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
    
    // Remove all lines
    func clear() {
        lines.removeAll()
        fieldNames.removeAll()
        if isVisible {
            updateDisplay()
        }
    }
    
    // Configure the number of visible lines
    func setLineCount(_ count: Int) {
        maxLines = max(1, count) // Ensure at least 1 line
        ensureMinimumLines()
        if isVisible {
            updateDisplay()
        }
    }
    
    // Register a custom name for a specific field position
    func registerField(name: String, line: Int, alignment: StatusAlignment) {
        fieldNames[name] = (line: line, alignment: alignment)
        ensureMinimumLines()
    }
    
    // Update text for a specific field by name
    func updateField(name: String, text: String) {
        guard let fieldInfo = fieldNames[name] else { return }
        updateField(line: fieldInfo.line, alignment: fieldInfo.alignment, text: text)
    }
    
    // Update text for a specific field by position
    func updateField(line: Int, alignment: StatusAlignment, text: String) {
        ensureMinimumLines()
        guard line >= 0 && line < lines.count else { return }
        
        // Find the region with matching alignment, or create new line if needed
        let currentLine = lines[line]
        var updatedRegions = currentLine.regions
        
        // Find existing region with same alignment
        if let regionIndex = updatedRegions.firstIndex(where: { $0.alignment == alignment }) {
            updatedRegions[regionIndex] = StatusRegion(text, alignment: alignment)
        } else {
            // Add new region, maintaining order: left, center, right
            let newRegion = StatusRegion(text, alignment: alignment)
            switch alignment {
            case .left:
                updatedRegions.insert(newRegion, at: 0)
            case .center:
                let rightIndex = updatedRegions.firstIndex(where: { $0.alignment == .right }) ?? updatedRegions.count
                updatedRegions.insert(newRegion, at: rightIndex)
            case .right:
                updatedRegions.append(newRegion)
            }
        }
        
        lines[line] = StatusLine(regions: updatedRegions)
        
        if isVisible {
            updateDisplay()
        }
    }
    
    // Ensure we have at least the required number of lines
    private func ensureMinimumLines() {
        while lines.count < maxLines {
            lines.append(StatusLine.simple(""))
        }
    }
    
    // Send current status to the controller for display
    private func updateDisplay() {
        guard isVisible else { return }
        controller?.displayStatusBar(lines: lines)
    }
}
