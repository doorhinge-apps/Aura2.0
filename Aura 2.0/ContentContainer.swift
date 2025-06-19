//
// Aura 2.0
// ContentContainer.swift
//
// Created on 6/11/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import SwiftData

struct ContentContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var spaces: [SpaceData]

    var body: some View {
        Group {
            if let selected = spaces.first {
                ContentView(selectedSpace: selected)
                    .scrollEdgeEffectDisabled(true)
                    .scrollEdgeEffectStyle(.hard, for: .top)
                    .statusBarHidden(true)
            } else {
                ProgressView()
                    .task {
                        let newSpace = SpaceData(
                            spaceIdentifier: UUID().uuidString,
                            spaceName: "Untitled",
                            isIncognito: false,
                            spaceBackgroundColors: ["8041E6", "A0F2FC"],
                            textColor: "ffffff"
                        )
                        modelContext.insert(newSpace)
                        try? modelContext.save()
                    }
            }
        }
    }
}
