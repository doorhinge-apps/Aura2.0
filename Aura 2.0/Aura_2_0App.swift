//
// Aura 2.0
// Aura_2_0App.swift
//
// Created on 6/10/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import SwiftData

@main
struct Aura_2_0App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SpaceData.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentContainerView()
        }
        .modelContainer(sharedModelContainer)
    }
}
