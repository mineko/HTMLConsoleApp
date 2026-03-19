//
//  StatusBar.swift
//  PressKit
//

import Foundation

/// Alignment for a text region within a status line.
public enum StatusAlignment {
    case left
    case center
    case right
}

/// Individual text region within a status line.
public struct StatusRegion {
    public let text: String
    public let alignment: StatusAlignment

    public init(_ text: String, alignment: StatusAlignment = .left) {
        self.text = text
        self.alignment = alignment
    }
}

/// A single line in the status bar, composed of one or more text regions.
public struct StatusLine {
    public let regions: [StatusRegion]

    public init(_ regions: StatusRegion...) {
        self.regions = Array(regions)
    }

    public init(regions: [StatusRegion]) {
        self.regions = regions
    }

    public static func simple(_ text: String, alignment: StatusAlignment = .left) -> StatusLine {
        return StatusLine(StatusRegion(text, alignment: alignment))
    }

    public static func leftRight(left: String, right: String) -> StatusLine {
        return StatusLine(
            StatusRegion(left, alignment: .left),
            StatusRegion(right, alignment: .right)
        )
    }

    public static func leftCenterRight(left: String, center: String, right: String) -> StatusLine {
        return StatusLine(
            StatusRegion(left, alignment: .left),
            StatusRegion(center, alignment: .center),
            StatusRegion(right, alignment: .right)
        )
    }
}

/// Manages the status bar display at the bottom of the console.
public class StatusBar {
    private var lines: [StatusLine] = []
    private var isVisible: Bool = false
    private weak var controller: ConsoleController?
    private var maxLines: Int = 2
    private var fieldNames: [String: (line: Int, alignment: StatusAlignment)] = [:]

    init(controller: ConsoleController) {
        self.controller = controller
    }

    public func setLines(_ lines: [StatusLine]) {
        self.lines = lines
        if isVisible { updateDisplay() }
    }

    public func show() {
        isVisible = true
        updateDisplay()
    }

    public func hide() {
        isVisible = false
        controller?.hideStatusBar()
    }

    public func toggle() {
        if isVisible { hide() } else { show() }
    }

    public func updateLine(at index: Int, with line: StatusLine) {
        guard index >= 0 else { return }
        while lines.count <= index {
            lines.append(StatusLine.simple(""))
        }
        lines[index] = line
        if isVisible { updateDisplay() }
    }

    public func clear() {
        lines.removeAll()
        fieldNames.removeAll()
        if isVisible { updateDisplay() }
    }

    public func setLineCount(_ count: Int) {
        maxLines = max(1, count)
        ensureMinimumLines()
        if isVisible { updateDisplay() }
    }

    public func registerField(name: String, line: Int, alignment: StatusAlignment) {
        fieldNames[name] = (line: line, alignment: alignment)
        ensureMinimumLines()
    }

    public func updateField(name: String, text: String) {
        guard let fieldInfo = fieldNames[name] else { return }
        updateField(line: fieldInfo.line, alignment: fieldInfo.alignment, text: text)
    }

    public func updateField(line: Int, alignment: StatusAlignment, text: String) {
        ensureMinimumLines()
        guard line >= 0 && line < lines.count else { return }

        let currentLine = lines[line]
        var updatedRegions = currentLine.regions

        if let regionIndex = updatedRegions.firstIndex(where: { $0.alignment == alignment }) {
            updatedRegions[regionIndex] = StatusRegion(text, alignment: alignment)
        } else {
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
        if isVisible { updateDisplay() }
    }

    private func ensureMinimumLines() {
        while lines.count < maxLines {
            lines.append(StatusLine.simple(""))
        }
    }

    private func updateDisplay() {
        guard isVisible else { return }
        controller?.displayStatusBar(lines: lines)
    }
}
