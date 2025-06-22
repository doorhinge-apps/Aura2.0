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
    
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        Group {
            if let selected = spaces.first {
                ContentView(selectedSpace: selected)
                    .scrollEdgeEffectDisabled(true)
                    .scrollEdgeEffectStyle(.hard, for: .top)
                    .statusBarHidden(true)
                    .onAppear {
                        let cutoff = Date().addingTimeInterval(-Double(settingsManager.closePrimaryTabsAfter) * 60)

                        for space in spaces {
                            let oldTabs = space.primaryTabs.filter { $0.timestamp < cutoff }

                            for tab in oldTabs {
                                space.removeTab(tab)
                                modelContext.delete(tab)
                            }
                        }
                        
                        try? modelContext.save()
                    }
                    .onOpenURL { url in
                        uiViewModel.currentSelectedTab = storageManager.newTab(unformattedString: url.absoluteString, space: selected, modelContext: modelContext).id
                    }
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
