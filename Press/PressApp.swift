//
//  PressApp.swift
//  Press
//
//  Created by Collin Pieper on 9/1/25.
//

import SwiftUI
import PressKit
import TestModule
import LayoutTestModule

@main
struct PressApp: App {
    init() {
        ModuleRegistry.shared.register(LayoutTestModule.self)
        ModuleRegistry.shared.register(TestModule.self)
    }

    var body: some Scene {
        WindowGroup {
            ConsoleView(module: "Layout Test")
        }
    }
}
