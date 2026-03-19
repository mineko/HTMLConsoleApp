//
//  LayoutScorer.swift
//  PressKit
//

import Foundation

/// Alignment options for image placement in the layout.
public enum ImageAlignment: String, CaseIterable {
    case left, right, center
}

/// Size category for placed images.
public enum ImageSizeCategory: String, CaseIterable {
    case small, medium, large

    /// Returns the width as a fraction of viewport width for a given alignment.
    func widthFraction(for alignment: ImageAlignment) -> CGFloat {
        switch (self, alignment) {
        case (.small, .center):  return 0.35
        case (.small, _):       return 0.22
        case (.medium, .center): return 0.50
        case (.medium, _):      return 0.33
        case (.large, .center):  return 0.70
        case (.large, _):       return 0.42
        }
    }
}

/// Cached layout state reported by the JS rendering layer.
public struct LayoutState {
    public var viewportWidth: CGFloat = 800
    public var viewportHeight: CGFloat = 600
    public var pixelsSinceLastImage: CGFloat = 1000
    public var outputHeight: CGFloat = 0
    public var recentAlignments: [ImageAlignment] = []

    public init() {}
}

/// Tunable parameters for the layout scoring algorithm.
public struct LayoutKnobs {
    /// How frequently images appear (0 = sparse, 1 = dense).
    public var density: CGFloat = 0.5
    /// How large images tend to be (0 = small, 1 = large).
    public var prominence: CGFloat = 0.5
    /// How much alignment varies (0 = repetitive, 1 = varied).
    public var variety: CGFloat = 0.5
    /// How much image priority overrides layout aesthetics (0 = aesthetics, 1 = priority).
    public var priorityBias: CGFloat = 0.5
    /// Minimum full-width text blocks before an image (0 = none, 1 = lots).
    public var textBefore: CGFloat = 0.5

    public init() {}

    public mutating func set(_ name: String, value: CGFloat) {
        let clamped = max(0, min(1, value))
        switch name.lowercased() {
        case "density":                         density = clamped
        case "prominence":                      prominence = clamped
        case "variety":                         variety = clamped
        case "priority", "prioritybias":        priorityBias = clamped
        case "textbefore":                      textBefore = clamped
        default: break
        }
    }

    public func get(_ name: String) -> CGFloat? {
        switch name.lowercased() {
        case "density":                         return density
        case "prominence":                      return prominence
        case "variety":                         return variety
        case "priority", "prioritybias":        return priorityBias
        case "textbefore":                      return textBefore
        default: return nil
        }
    }
}

/// Result of the layout scoring decision.
public struct PlacementDecision {
    public let shouldPlace: Bool
    public let alignment: ImageAlignment
    public let sizeCategory: ImageSizeCategory
    public let widthFraction: CGFloat

    public static let skip = PlacementDecision(
        shouldPlace: false, alignment: .center,
        sizeCategory: .medium, widthFraction: 0
    )
}

/// Scores candidate image placements and selects the optimal layout.
public class LayoutScorer {
    public var knobs = LayoutKnobs()
    public private(set) var layoutState = LayoutState()

    public init() {}

    /// Update cached layout state from a JSON string produced by JS getLayoutState().
    public func updateLayoutState(from json: String) {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        if let v = dict["viewportWidth"] as? Double { layoutState.viewportWidth = CGFloat(v) }
        if let v = dict["viewportHeight"] as? Double { layoutState.viewportHeight = CGFloat(v) }
        if let v = dict["pixelsSinceLastImage"] as? Double { layoutState.pixelsSinceLastImage = CGFloat(v) }
        if let v = dict["outputHeight"] as? Double { layoutState.outputHeight = CGFloat(v) }
    }

    /// Score candidate placements for an image with the given priority.
    public func scorePlacement(priority: CGFloat) -> PlacementDecision {
        // Minimum pixel spacing before another image, scaled by density knob (150–550 px).
        let minSpacing = 150 + (1.0 - knobs.density) * 400

        if layoutState.pixelsSinceLastImage < minSpacing {
            let priorityOverride = priority * knobs.priorityBias
            if priorityOverride < 0.7 {
                return .skip
            }
        }

        var bestScore: CGFloat = -1
        var bestCandidate: PlacementDecision = .skip

        let candidateAlignments: [ImageAlignment] =
            layoutState.viewportWidth < 500 ? [.center] : ImageAlignment.allCases

        for alignment in candidateAlignments {
            for size in ImageSizeCategory.allCases {
                let wf = size.widthFraction(for: alignment)
                let imageWidth = wf * layoutState.viewportWidth

                // Hard constraint: floated images must leave ≥150 px for text.
                if alignment != .center {
                    let remaining = layoutState.viewportWidth - imageWidth - 40
                    if remaining < 150 { continue }
                }

                let score = computeScore(alignment: alignment, size: size,
                                         widthFraction: wf, priority: priority)
                if score > bestScore {
                    bestScore = score
                    bestCandidate = PlacementDecision(
                        shouldPlace: true, alignment: alignment,
                        sizeCategory: size, widthFraction: wf
                    )
                }
            }
        }

        let skipThreshold: CGFloat = 0.3 - (priority * knobs.priorityBias * 0.2)
        if bestScore < skipThreshold { return .skip }

        if bestCandidate.shouldPlace {
            layoutState.recentAlignments.insert(bestCandidate.alignment, at: 0)
            if layoutState.recentAlignments.count > 5 {
                layoutState.recentAlignments.removeLast()
            }
            layoutState.pixelsSinceLastImage = 0
        }

        return bestCandidate
    }

    // MARK: - Scoring Components

    private func computeScore(alignment: ImageAlignment, size: ImageSizeCategory,
                               widthFraction: CGFloat, priority: CGFloat) -> CGFloat {
        var score: CGFloat = 0.5

        // 1. Spacing — more text since last image → higher score.
        let spacingNorm = min(layoutState.pixelsSinceLastImage / 600, 1.0)
        score += spacingNorm * 0.3

        // 2. Size appropriateness — penalise deviation from prominence preference.
        let sizeValue: CGFloat
        switch size {
        case .small:  sizeValue = 0.0
        case .medium: sizeValue = 0.5
        case .large:  sizeValue = 1.0
        }
        score -= abs(sizeValue - knobs.prominence) * 0.2

        // 3. Variety — penalise repeating the same alignment.
        score -= computeVarietyPenalty(alignment: alignment) * knobs.variety * 0.3

        // 4. Priority bonus.
        score += priority * knobs.priorityBias * 0.2

        // 5. Viewport-aware adjustments.
        if layoutState.viewportWidth < 600 {
            if alignment == .center { score += 0.1 }
            if size == .large { score -= 0.15 }
        } else if layoutState.viewportWidth > 1200 {
            if alignment != .center { score += 0.05 }
        }

        return score
    }

    private func computeVarietyPenalty(alignment: ImageAlignment) -> CGFloat {
        guard !layoutState.recentAlignments.isEmpty else { return 0 }

        var penalty: CGFloat = 0

        if layoutState.recentAlignments.first == alignment { penalty += 0.6 }
        if layoutState.recentAlignments.count > 1 && layoutState.recentAlignments[1] == alignment {
            penalty += 0.3
        }
        let sameCount = layoutState.recentAlignments.filter { $0 == alignment }.count
        penalty += CGFloat(sameCount) * 0.1

        return min(penalty, 1.0)
    }
}
