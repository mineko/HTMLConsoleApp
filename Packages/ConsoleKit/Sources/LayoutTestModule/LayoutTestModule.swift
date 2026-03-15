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
        "River Crossing", "The Old Library", "Frozen Lake", "Dragon's Lair",
        "Village Square", "The Armory", "Damp Cellar", "Watchtower",
        "Enchanted Grove", "Crumbling Bridge", "The Catacombs", "Alchemist's Study",
        "Harbor District", "Moonlit Garden", "The Forge", "Smuggler's Cave",
        "Wizard's Tower", "The Barracks", "Crystal Cavern", "Ruined Temple",
        "Windswept Cliff", "The Apothecary", "Throne of Bones", "Whispering Woods",
        "The Arena", "Sunken Chapel", "Merchant's Quarter", "The Ossuary",
        "Candlelit Passage", "Rooftop Terrace", "The Undercroft", "Banquet Hall",
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
        "The air smells of damp stone.",
        "A torch sputters on the wall.",
        "You hear dripping water.",
        "The floor is slippery here.",
        "Cobwebs hang from the ceiling.",
        "A rat scurries past your feet.",
        "The passage narrows ahead.",
        "You notice scratch marks on the wall.",
        "An iron gate blocks the way west.",
        "There is a wooden chest here.",
        "You feel a draft from above.",
        "The walls are covered in moss.",
        "A broken sword lies on the ground.",
        "You smell smoke.",
        "Faint music drifts from somewhere below.",
        "The door creaks open.",
        "A pile of bones sits in the corner.",
        "Your torch flickers and dims.",
        "You hear a distant roar.",
        "The key doesn't fit.",
        "A raven watches you from a ledge.",
        "The bridge looks unstable.",
        "You found 12 gold coins.",
        "The potion tastes bitter.",
        "A hidden switch clicks.",
        "The trap has already been sprung.",
        "Vines cover the entrance.",
        "The map shows a passage north.",
        "A bell tolls somewhere above.",
        "The water is too deep to wade.",
    ]

    private let mediumDescriptions = [
        "A narrow stone corridor stretches before you, its walls slick with moisture. Torches flicker at irregular intervals, casting long shadows that seem to move on their own.",
        "The tavern is warm and noisy. A bard strums a lute in the corner while patrons argue over cards. The barkeep eyes you with casual suspicion.",
        "You find yourself at the edge of a vast underground lake. The water is impossibly still, reflecting the pale glow of phosphorescent fungi clinging to the cavern ceiling.",
        "In the heart of the dimly-lit chamber, a grand, weathered chest stands resolute, its antiquated beauty radiating a silent, enigmatic allure.",
        "The courtyard is overgrown with ivy and wild roses. A crumbling fountain stands at its center, long dry, with a moss-covered statue of a forgotten hero gazing skyward.",
        "Shelves line every wall from floor to ceiling, stuffed with leather-bound volumes and loose scrolls. Dust motes drift through a single beam of light from a high window.",
        "A rickety wooden bridge spans a chasm of indeterminate depth. The ropes creak ominously as the wind picks up, and you can hear the rush of water far below.",
        "The smithy radiates heat even from the doorway. The blacksmith hammers a glowing blade, sending sparks cascading across the soot-darkened floor with each strike.",
        "An ornate mirror hangs on the far wall, its gilded frame tarnished with age. Your reflection looks back at you, but something about it seems slightly wrong.",
        "The garden has gone wild. Once-orderly hedgerows have twisted into a labyrinth of thorns, and the stone path is barely visible beneath creeping vines and fallen leaves.",
        "A heavy oak table dominates the center of the room, laden with half-eaten food and overturned goblets. Whatever feast was held here ended in haste.",
        "The cell is small and dank, with a pile of moldy straw in one corner and scratch marks tallying the days on the wall. The iron door stands ajar.",
        "Morning mist clings to the valley floor, obscuring the path ahead. The only sound is the distant call of a hawk circling high above the treeline.",
        "The apothecary's shelves are lined with jars of every size and color. Labels in a cramped hand identify their contents: wolfsbane, nightshade, dragon's breath.",
        "A campfire's embers still glow faintly, surrounded by bedrolls and scattered provisions. Whoever made camp here left recently and in a hurry.",
        "The throne sits empty atop a dais of black marble, its velvet cushion faded and torn. The hall stretches out before it, silent as a tomb.",
        "Stalactites hang like stone teeth from the cavern roof, some nearly touching the stalagmites rising to meet them. The air is cool and carries a mineral tang.",
        "A narrow canal runs through the chamber, its dark water flowing with surprising speed. A small boat is tied to an iron ring set into the stone bank.",
        "The observatory's domed ceiling is open to the night sky. A massive brass telescope points upward, its gears and dials green with verdigris.",
        "Tapestries line the corridor, their woven scenes depicting a history you don't recognize. Knights battle creatures that shouldn't exist, and cities float among clouds.",
        "The market stalls are empty now, their canvas awnings flapping in the breeze. A few forgotten apples roll across the cobblestones.",
        "A spiral staircase of white marble ascends through an opening in the ceiling. Each step is carved with a different rune that glows faintly blue when touched.",
        "The graveyard is ancient, its headstones worn smooth by centuries of rain. Some graves have sunk, others have shifted, and a few stand open.",
        "Water pours from a crack in the wall, pooling in a natural basin before overflowing down the passage. The stone around it is stained green with algae.",
    ]

    private let longDescriptions = [
        "Wrapped in the tender embrace of a quaint, snug cottage, you find yourself ensconced in a warm, inviting sanctuary. The crackling fireplace hums softly, casting long, dancing shadows on the worn-out, rustic walls. The scent of freshly baked bread wafts through the air, a comforting reminder of the hearth and home.",
        "The forest canopy breaks open here, allowing a shaft of golden sunlight to illuminate a small meadow carpeted with wildflowers. Butterflies drift lazily between blooms, and somewhere nearby a brook babbles over smooth stones. It feels impossibly peaceful given what you've just escaped.",
        "The merchant's stall is a riot of color and scent. Silk scarves in every imaginable hue hang from wooden pegs, while baskets overflow with exotic spices that tingle in your nostrils. The merchant himself is a wiry old man with knowing eyes and ink-stained fingers.",
        "You descend the spiral staircase, each step echoing in the hollow tower. The air grows colder and damper with every turn. By the time you reach the bottom, your breath comes in visible puffs and the stone walls glisten with frost.",
        "Beyond the room's shadows, the flickering torchlight reveals a narrow, stone-hewn passage, leading ever upward and vanishing into the gloom of the ancient fortress, beckoning you northward. The stones underfoot are worn smooth by centuries of footsteps.",
        "The great hall stretches before you, its vaulted ceiling lost in shadow above. Tattered banners hang from iron brackets along the walls, their heraldry faded beyond recognition. A long table runs the length of the room, set for a feast that never came, silver tarnished and candles melted to stumps.",
        "You emerge from the tunnel onto a narrow ledge overlooking a vast cavern. Below, an underground river winds through a forest of pale, eyeless trees that have never known sunlight. Bioluminescent insects drift among the branches like earthbound stars, casting an eerie blue-green glow over the silent landscape.",
        "The library is a monument to forgotten knowledge. Books are stacked not just on shelves but in towering columns that reach toward the distant ceiling, creating narrow canyons of leather and parchment. A wheeled ladder leans against one wall, and somewhere deep in the stacks you can hear pages turning, though you see no one.",
        "The harbor is quiet at this hour, the fishing boats rocking gently at their moorings. Lanterns sway on their posts, painting shifting patterns of gold on the dark water. The smell of salt and tar mingles with something sweeter from the bakery on the quay, where the ovens are already lit for the morning's bread.",
        "A grand staircase sweeps upward in a graceful curve, its marble balustrade carved with climbing roses so detailed you can almost smell them. Crystal chandeliers hang overhead, dark now but still catching the light from your torch and scattering it in a thousand tiny rainbows across the peeling wallpaper.",
        "The battlefield stretches to the horizon, silent now save for the wind that stirs the trampled grass. Broken weapons and shattered shields litter the ground, half-buried in mud. Crows circle overhead in lazy spirals, and in the distance a single banner still stands, its colors too stained to read.",
        "The alchemist's workshop is a controlled disaster. Glass vessels bubble and hiss over carefully calibrated flames, connected by an impossible tangle of copper tubing. Shelves sag under the weight of ingredients both mundane and exotic, and the air shimmers with heat and the sharp scent of sulfur and citrus.",
        "You stand at the edge of a frozen waterfall, its cascade arrested mid-flow by the bitter cold. The ice is clear enough to see the water still moving beneath, sluggish and dark. Above, the cliff face is sheathed in glittering frost, and icicles as long as swords hang from every outcropping.",
        "The temple's interior is dominated by a massive stone idol, its features worn to ambiguity by the touch of countless worshippers over the centuries. Offerings of fruit and coin lie at its base, some fresh. Incense smoke coils upward from bronze censers, filling the space with a heavy, sweet fragrance that makes your eyes water.",
        "The ruins of the old castle cling to the hilltop like a broken crown. Walls that once held back armies now crumble at a touch, their stones scattered down the slope among wildflowers and thistle. From the highest remaining tower, you can see the river valley stretching south, the road winding through it like a silver thread.",
        "The underground market thrums with furtive energy. Vendors sell their wares from alcoves carved into the tunnel walls, their faces lit from below by guttering candles. The goods on offer range from the mundane to the deeply questionable, and the clientele keep their hoods up and their voices low.",
        "A vast greenhouse sprawls before you, its glass panels fogged with humidity. Inside, plants from every corner of the world grow in riotous profusion, many of them species you've never seen before. Vines thick as your arm climb the iron framework, and flowers the size of dinner plates turn slowly to track your movement.",
        "The clock tower's mechanism fills the entire room, a cathedral of brass gears and steel springs. The main gear alone is taller than you, and the pendulum swings with a deep, resonant pulse that you feel in your chest. Everything is coated in a fine layer of oil, and the air tastes of metal.",
        "The desert stretches endlessly under a sky bleached white by the sun. Dunes rise and fall like frozen waves, their crests trailing streamers of sand in the hot wind. In the distance, a dark smudge on the horizon might be an oasis or might be nothing at all, and your waterskin is nearly empty.",
        "The feast hall of the dwarven city is carved from living rock, its pillars shaped like ancient kings bearing the weight of the mountain on their shoulders. A fire pit runs the length of the central table, its flames fed by vents in the stone that channel heat from somewhere deep below. The smell of roasted meat and dark ale fills the air.",
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
    private func makePlaceholder(priority: CGFloat) -> (uri: String, caption: String, width: Int, height: Int) {
        let cfg = imageConfigs.randomElement()!
        let pri = String(format: "%.2f", priority)
        let svg = "<svg xmlns='http://www.w3.org/2000/svg' width='\(cfg.w)' height='\(cfg.h)'>"
            + "<rect width='100%' height='100%' fill='\(cfg.color)' rx='8'/>"
            + "<text x='50%' y='40%' fill='white' font-family='sans-serif' font-size='20' text-anchor='middle' dy='.3em'>\(cfg.label) \(cfg.w)x\(cfg.h)</text>"
            + "<text x='50%' y='60%' fill='rgba(255,255,255,0.8)' font-family='sans-serif' font-size='20' text-anchor='middle' dy='.3em'>Priority: \(pri)</text>"
            + "</svg>"
        let encoded = Data(svg.utf8).base64EncodedString()
        return (uri: "data:image/svg+xml;base64,\(encoded)", caption: cfg.label, width: cfg.w, height: cfg.h)
    }

    override func configureStatusBar() {
        statusBar?.setLineCount(1)
        statusBar?.registerField(name: "module", line: 0, alignment: .center)
        statusBar?.registerField(name: "knobs", line: 0, alignment: .left)
        statusBar?.registerField(name: "status", line: 0, alignment: .right)
        updateKnobsDisplay()
    }

    override func menuItems() -> [MenuItem] {
        let controlMenu = Menu(items: [
            MenuItem(id: "stream", title: "Stream", action: { [weak self] in self?.startStream() }),
            MenuItem(id: "stop", title: "Stop", action: { [weak self] in self?.stopStream() }),
            MenuItem(id: "reset", title: "Reset", action: { [weak self] in self?.resetContent() }),
        ], title: "Control")

        return [
            MenuItem(id: "control", title: "Control", submenu: controlMenu),
            MenuItem(id: "help", title: "Help", action: { [weak self] in self?.showHelp() }),
        ]
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
        default:
            addOutput("Unknown command: \(input). Type 'help' for commands.")
        }

        controller?.showPrompt()
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
    }

    private func showKnobs() {
        guard let knobs = getLayoutKnobs() else { return }
        addOutput("--- Layout Knobs ---")
        addOutput("density:    \(String(format: "%.2f", knobs.density))")
        addOutput("prominence: \(String(format: "%.2f", knobs.prominence))")
        addOutput("variety:    \(String(format: "%.2f", knobs.variety))")
        addOutput("priority:   \(String(format: "%.2f", knobs.priorityBias))")
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
                addContent(text: text, image: img.uri, caption: img.caption, priority: priority, imageWidth: img.width, imageHeight: img.height)
            } else {
                addContent(text: text)
            }
        }
    }

    private func startStream() {
        stopStream()
        statusBar?.updateField(name: "status", text: "Streaming")
        addOutput("Streaming started. Type 'stop' to end.")

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
            addContent(text: text, image: img.uri, caption: img.caption, priority: priority, imageWidth: img.width, imageHeight: img.height)
        } else {
            addContent(text: text)
        }
    }

    private func resetContent() {
        stopStream()
        sceneQueue = []
        clearOutput()
        addOutput("Output cleared. Type 'go' or 'stream' to generate content.")
    }
}
