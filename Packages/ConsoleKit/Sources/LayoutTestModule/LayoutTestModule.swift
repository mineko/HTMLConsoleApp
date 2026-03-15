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
    private var sceneQueue: [String] = []

    private let headers = [
        "Small Cottage", "Forest Clearing", "The Great Hall", "Dungeon Entrance",
        "Market Square", "The Throne Room", "Winding Staircase", "Abandoned Chapel",
        "River Crossing", "The Old Library",
    ]

    private let shortLines = [
        "You see a stick and a mushroom.",
        "There is an exit south.",
        "The door is locked.",
        "You hear footsteps in the distance.",
        "A cold wind blows through the passage.",
        "Nothing happens.",
        "It is pitch dark.",
        "There are exits north and east.",
        "A faint light glimmers ahead.",
        "Something moves in the shadows.",
    ]

    private let mediumDescriptions = [
        "A narrow stone corridor stretches before you, its walls slick with moisture. Torches flicker at irregular intervals, casting long shadows that seem to move on their own.",
        "The tavern is warm and noisy. A bard strums a lute in the corner while patrons argue over cards. The barkeep eyes you with casual suspicion.",
        "You find yourself at the edge of a vast underground lake. The water is impossibly still, reflecting the pale glow of phosphorescent fungi clinging to the cavern ceiling.",
        "In the heart of the dimly-lit chamber, a grand, weathered chest stands resolute, its antiquated beauty radiating a silent, enigmatic allure.",
        "The courtyard is overgrown with ivy and wild roses. A crumbling fountain stands at its center, long dry, with a moss-covered statue of a forgotten hero gazing skyward.",
        "Shelves line every wall from floor to ceiling, stuffed with leather-bound volumes and loose scrolls. Dust motes drift through a single beam of light from a high window.",
    ]

    private let longDescriptions = [
        "Wrapped in the tender embrace of a quaint, snug cottage, you find yourself ensconced in a warm, inviting sanctuary. The crackling fireplace hums softly, casting long, dancing shadows on the worn-out, rustic walls. The scent of freshly baked bread wafts through the air, a comforting reminder of the hearth and home.",
        "The forest canopy breaks open here, allowing a shaft of golden sunlight to illuminate a small meadow carpeted with wildflowers. Butterflies drift lazily between blooms, and somewhere nearby a brook babbles over smooth stones. It feels impossibly peaceful given what you've just escaped.",
        "The merchant's stall is a riot of color and scent. Silk scarves in every imaginable hue hang from wooden pegs, while baskets overflow with exotic spices that tingle in your nostrils. The merchant himself is a wiry old man with knowing eyes and ink-stained fingers.",
        "You descend the spiral staircase, each step echoing in the hollow tower. The air grows colder and damper with every turn. By the time you reach the bottom, your breath comes in visible puffs and the stone walls glisten with frost.",
        "Beyond the room's shadows, the flickering torchlight reveals a narrow, stone-hewn passage, leading ever upward and vanishing into the gloom of the ancient fortress, beckoning you northward. The stones underfoot are worn smooth by centuries of footsteps.",
    ]

    /// Generate a "scene" — a header followed by a structured sequence of descriptions.
    private func generateScene() -> [String] {
        var scene: [String] = []

        // Header
        scene.append(headers.randomElement()!)

        // Primary description: usually medium, sometimes long, rarely short
        switch Int.random(in: 0...9) {
        case 0...5:  scene.append(mediumDescriptions.randomElement()!)
        case 6...8:  scene.append(longDescriptions.randomElement()!)
        default:     scene.append(shortLines.randomElement()!)
        }

        // 0-3 follow-up lines (short or medium, occasionally long)
        let followUpCount = Int.random(in: 0...3)
        for _ in 0..<followUpCount {
            switch Int.random(in: 0...9) {
            case 0...4:  scene.append(shortLines.randomElement()!)
            case 5...7:  scene.append(mediumDescriptions.randomElement()!)
            default:     scene.append(longDescriptions.randomElement()!)
            }
        }

        return scene
    }

    // Image template configs
    private let imageConfigs: [(color: String, w: Int, h: Int, label: String)] = [
        ("#4A90D9", 400, 300, "Landscape"),
        ("#D94A4A", 300, 400, "Portrait"),
        ("#4AD97A", 400, 400, "Square"),
        ("#D9A04A", 500, 250, "Wide"),
        ("#9B59B6", 250, 500, "Tall"),
        ("#1ABC9C", 600, 300, "Panoramic"),
        ("#E67E22", 350, 350, "Medium"),
        ("#3498DB", 450, 280, "Scene"),
    ]

    /// Generate an SVG placeholder with metadata baked into the image
    private func makePlaceholder(priority: CGFloat) -> (uri: String, caption: String) {
        let cfg = imageConfigs.randomElement()!
        let pri = String(format: "%.2f", priority)
        let svg = "<svg xmlns='http://www.w3.org/2000/svg' width='\(cfg.w)' height='\(cfg.h)'>"
            + "<rect width='100%' height='100%' fill='\(cfg.color)' rx='8'/>"
            + "<text x='50%' y='40%' fill='white' font-family='sans-serif' font-size='20' text-anchor='middle' dy='.3em'>\(cfg.label) \(cfg.w)x\(cfg.h)</text>"
            + "<text x='50%' y='60%' fill='rgba(255,255,255,0.8)' font-family='sans-serif' font-size='20' text-anchor='middle' dy='.3em'>Priority: \(pri)</text>"
            + "</svg>"
        let encoded = Data(svg.utf8).base64EncodedString()
        return (uri: "data:image/svg+xml;base64,\(encoded)", caption: cfg.label)
    }

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

    private func nextTextBlock() -> String {
        if sceneQueue.isEmpty {
            sceneQueue = generateScene()
        }
        return sceneQueue.removeFirst()
    }

    private func generateContent(count: Int) {
        for i in 0..<count {
            let text = nextTextBlock()

            if i > 0 && Int.random(in: 0...2) == 0 {
                let priority = CGFloat.random(in: 0.1...1.0)
                let img = makePlaceholder(priority: priority)
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
        let text = nextTextBlock()

        if Int.random(in: 0...2) == 0 {
            let priority = CGFloat.random(in: 0.1...1.0)
            let img = makePlaceholder(priority: priority)
            addContent(text: text, image: img.uri, caption: img.caption, priority: priority)
        } else {
            addContent(text: text)
        }
    }

    private func resetContent() {
        stopStream()
        sceneQueue = []
        clearOutput()
        addOutput("Output cleared. Type 'go' or 'stream' to generate content.")
        controller?.showPrompt()
    }
}
