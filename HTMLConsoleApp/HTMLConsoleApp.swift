//
//  HTMLConsoleApp.swift
//  HTMLConsoleApp
//
//  Created by Collin Pieper on 9/1/25.
//

import SwiftUI
import ConsoleKit
import TestModule

@main
struct HTMLConsoleAppApp: App {
    init() {
        ModuleRegistry.shared.register(TestModule.self)
    }

    var body: some Scene {
        WindowGroup {
            ConsoleView()
        }
    }
}
