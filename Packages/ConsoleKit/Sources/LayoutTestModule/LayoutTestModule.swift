//
//  LayoutTestModule.swift
//  LayoutTestModule
//

import Foundation
import ConsoleKit

/// Test module for tuning layout scorer parameters.
/// Streams lorem ipsum text with placeholder images to evaluate placement.
public struct LayoutTestModule: ConsoleModule {
    public static var moduleInfo: ModuleInfo {
        ModuleInfo(
            name: "Layout Test",
            version: "1.0.0",
            description: "Lorem ipsum generator for tuning image layout parameters",
            author: "HTMLConsoleApp",
            minAppVersion: "1.0.0"
        )
    }

    public static func createEngine(controller: ConsoleController) -> Engine {
        return LayoutTestEngine(controller: controller)
    }
}

// MARK: - Engine

class LayoutTestEngine: Engine {
    private var streamTimer: Timer?
    private var paragraphIndex = 0

    private let paragraphs = [
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
        "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
        "Curabitur pretium tincidunt lacus. Nulla gravida orci a odio. Nullam varius, turpis et commodo pharetra, est eros bibendum elit, nec luctus magna felis sollicitudin mauris. Integer in mauris eu nibh euismod gravida.",
        "Praesent blandit laoreet nibh. Fusce convallis metus id felis luctus adipiscing. Pellentesque egestas, neque sit amet convallis pulvinar, justo nulla eleifend augue, ac auctor orci leo non est.",
        "Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae. Morbi lacinia molestie dui. Praesent blandit dolor sed nunc rutrum venenatis.",
        "Sed non velit cursus arcu aliquet laoreet. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nulla quam. Aenean ornare velit lacus.",
        "Donec vitae sapien ut libero venenatis faucibus. Nullam quis ante. Etiam sit amet orci eget eros faucibus tincidunt. Duis leo. Sed fringilla mauris sit amet nibh.",
        "Maecenas tempus, tellus eget condimentum rhoncus, sem quam semper libero, sit amet adipiscing sem neque sed ipsum. Nam quam nunc, blandit vel, luctus pulvinar, hendrerit id, lorem.",
        "Phasellus viverra nulla ut metus varius laoreet. Quisque rutrum. Aenean imperdiet. Etiam ultricies nisi vel augue. Curabitur ullamcorper ultricies nisi. Nam eget dui. Etiam rhoncus.",
        "Fusce risus nisl, viverra et, tempor et, pretium in, sapien. Donec venenatis vulputate lorem. Morbi nec metus. Phasellus blandit leo ut odio. Maecenas ullamcorper, dui et placerat feugiat.",
        "Aliquam erat volutpat. Nunc fermentum tortor ac porta dapibus. In rutrum ac purus sit amet tempus. Suspendisse potenti. Etiam pharetra lacus sed interdum auctor.",
        "Vivamus elementum semper nisi. Aenean vulputate eleifend tellus. Aenean leo ligula, porttitor eu, consequat vitae, eleifend ac, enim. Aliquam lorem ante, dapibus in, viverra quis, feugiat a, tellus."
    ]

    // SVG placeholder images as data URIs with different colors/aspect ratios
    private let placeholderImages: [(uri: String, caption: String)] = {
        let configs: [(color: String, w: Int, h: Int, label: String)] = [
            ("#4A90D9", 400, 300, "Landscape"),
            ("#D94A4A", 300, 400, "Portrait"),
            ("#4AD97A", 400, 400, "Square"),
            ("#D9A04A", 500, 250, "Wide"),
            ("#9B59B6", 250, 500, "Tall"),
            ("#1ABC9C", 600, 300, "Panoramic"),
            ("#E67E22", 350, 350, "Medium"),
            ("#3498DB", 450, 280, "Scene"),
        ]
        return configs.map { cfg in
            let svg = "<svg xmlns='http://www.w3.org/2000/svg' width='\(cfg.w)' height='\(cfg.h)'>"
                + "<rect width='100%' height='100%' fill='\(cfg.color)' rx='8'/>"
                + "<text x='50%' y='50%' fill='white' font-family='sans-serif' font-size='20' text-anchor='middle' dy='.3em'>\(cfg.label) \(cfg.w)x\(cfg.h)</text>"
                + "</svg>"
            let encoded = Data(svg.utf8).base64EncodedString()
            return (uri: "data:image/svg+xml;base64,\(encoded)", caption: cfg.label)
        }
    }()

    override func configureStatusBar() {
        statusBar?.setLineCount(1)
        statusBar?.registerField(name: "module", line: 0, alignment: .center)
        statusBar?.registerField(name: "knobs", line: 0, alignment: .left)
        statusBar?.registerField(name: "status", line: 0, alignment: .right)
        updateKnobsDisplay()
    }

    override func start() {
        statusBar?.show()
        statusBar?.updateField(name: "module", text: "Layout Test")
        statusBar?.updateField(name: "status", text: "Ready")
        addOutput("Layout Test Module - tune image placement parameters")
        addOutput("Commands: go [N], stream, stop, reset, knobs, help")
        addOutput("Knobs: density, prominence, variety, priority [0-1]")
        controller?.showPrompt()
    }

    override func processInput(_ input: String) {
        let parts = input.trimmingCharacters(in: .whitespaces).lowercased().split(separator: " ")
        guard let command = parts.first else {
            controller?.showPrompt()
            return
        }

        switch command {
        case "help":
            showHelp()
        case "go":
            let count = parts.count > 1 ? Int(parts[1]) ?? 5 : 5
            generateContent(count: count)
        case "stream":
            startStream()
        case "stop":
            stopStream()
        case "reset":
            resetContent()
        case "knobs":
            showKnobs()
        case "density", "prominence", "variety", "priority":
            if parts.count > 1, let value = Double(parts[1]) {
                setLayoutKnob(String(command), value: CGFloat(value))
                updateKnobsDisplay()
                addOutput("\(command) set to \(String(format: "%.2f", value))")
            } else {
                addOutput("Usage: \(command) <0.0-1.0>")
            }
            controller?.showPrompt()
        default:
            addOutput("Unknown command: \(input). Type 'help' for commands.")
            controller?.showPrompt()
        }
    }

    // MARK: - Commands

    private func showHelp() {
        addOutput("--- Layout Test Commands ---")
        addOutput("go [N]      - Generate N content blocks (default 5)")
        addOutput("stream      - Auto-generate content every 1.5s")
        addOutput("stop        - Stop auto-generation")
        addOutput("reset       - Clear output and reset state")
        addOutput("knobs       - Show current knob values")
        addOutput("density N   - Set density (0=sparse, 1=dense)")
        addOutput("prominence N - Set prominence (0=small, 1=large)")
        addOutput("variety N   - Set variety (0=repetitive, 1=varied)")
        addOutput("priority N  - Set priority bias (0=aesthetics, 1=priority)")
        controller?.showPrompt()
    }

    private func showKnobs() {
        guard let knobs = getLayoutKnobs() else { return }
        addOutput("--- Layout Knobs ---")
        addOutput("density:    \(String(format: "%.2f", knobs.density))")
        addOutput("prominence: \(String(format: "%.2f", knobs.prominence))")
        addOutput("variety:    \(String(format: "%.2f", knobs.variety))")
        addOutput("priority:   \(String(format: "%.2f", knobs.priorityBias))")
        controller?.showPrompt()
    }

    private func updateKnobsDisplay() {
        guard let knobs = getLayoutKnobs() else { return }
        let display = "D:\(String(format: "%.1f", knobs.density)) P:\(String(format: "%.1f", knobs.prominence)) V:\(String(format: "%.1f", knobs.variety)) PB:\(String(format: "%.1f", knobs.priorityBias))"
        statusBar?.updateField(name: "knobs", text: display)
    }

    private func generateContent(count: Int) {
        for i in 0..<count {
            let text = paragraphs[paragraphIndex % paragraphs.count]
            paragraphIndex += 1

            // Every 2-3 blocks, attach an image with random priority
            if i > 0 && Int.random(in: 0...2) == 0 {
                let img = placeholderImages.randomElement()!
                let priority = CGFloat.random(in: 0.1...1.0)
                addContent(text: text, image: img.uri, caption: img.caption, priority: priority)
            } else {
                addContent(text: text)
            }
        }
        controller?.showPrompt()
    }

    private func startStream() {
        stopStream()
        statusBar?.updateField(name: "status", text: "Streaming")
        addOutput("Streaming started. Type 'stop' to end.")
        controller?.showPrompt()

        streamTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.streamTick()
        }
    }

    private func stopStream() {
        streamTimer?.invalidate()
        streamTimer = nil
        statusBar?.updateField(name: "status", text: "Ready")
    }

    private func streamTick() {
        let text = paragraphs[paragraphIndex % paragraphs.count]
        paragraphIndex += 1

        if Int.random(in: 0...2) == 0 {
            let img = placeholderImages.randomElement()!
            let priority = CGFloat.random(in: 0.1...1.0)
            addContent(text: text, image: img.uri, caption: img.caption, priority: priority)
        } else {
            addContent(text: text)
        }
    }

    private func resetContent() {
        stopStream()
        paragraphIndex = 0
        clearOutput()
        addOutput("Output cleared. Type 'go' or 'stream' to generate content.")
        controller?.showPrompt()
    }
}
