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
                    //.scrollEdgeEffectDisabled(true)
                    .modifier(ScrollEdgeDisabledIfAvailable())
                    .modifier(ScrollEdgeIfAvailable())
                    //.scrollEdgeEffectStyle(.hard, for: .top)
                    .statusBarHidden(true)
                    .onAppear {
                        let cutoff = Date().addingTimeInterval(-Double(settingsManager.closePrimaryTabsAfter) * 60)

                        for space in spaces {
                            // Clean up old tabs from the new group structure
                            cleanupOldTabsFromGroups(space: space, cutoff: cutoff, modelContext: modelContext)
                            
                            // Also clean up legacy tabs for migration
                            let oldTabs = space.primaryTabs.filter { $0.timestamp < cutoff }
                            for tab in oldTabs {
                                if let spaceTabs = space.tabs,
                                   let index = spaceTabs.firstIndex(where: { $0.id == tab.id }) {
                                    space.tabs?.remove(at: index)
                                    modelContext.delete(tab)
                                }
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

// MARK: - Helper Functions
private func cleanupOldTabsFromGroups(space: SpaceData, cutoff: Date, modelContext: ModelContext) {
    let primaryGroups = space.primaryTabGroups ?? []
    let pinnedGroups = space.pinnedTabGroups ?? []
    let favoriteGroups = space.favoriteTabGroups ?? []
    let allGroups = primaryGroups + pinnedGroups + favoriteGroups
    
    for group in allGroups {
        var groupIsEmpty = true
        
        let tabRows = group.tabRows ?? []
        for row in tabRows {
            let rowTabs = row.tabs ?? []
            let oldTabs = rowTabs.filter { $0.timestamp < cutoff }
            
            for tab in oldTabs {
                if let index = row.tabs?.firstIndex(where: { $0.id == tab.id }) {
                    row.tabs?.remove(at: index)
                    modelContext.delete(tab)
                }
            }
            
            if !(row.tabs?.isEmpty ?? true) {
                groupIsEmpty = false
            }
        }
        
        // Remove empty rows
        group.tabRows?.removeAll { $0.tabs?.isEmpty ?? true }
        
        // If the entire group is empty, mark for deletion
        if groupIsEmpty || (group.tabRows?.isEmpty ?? true) {
            if let primaryIndex = space.primaryTabGroups?.firstIndex(where: { $0.id == group.id }) {
                space.primaryTabGroups?.remove(at: primaryIndex)
            }
            if let pinnedIndex = space.pinnedTabGroups?.firstIndex(where: { $0.id == group.id }) {
                space.pinnedTabGroups?.remove(at: pinnedIndex)
            }
            if let favoriteIndex = space.favoriteTabGroups?.firstIndex(where: { $0.id == group.id }) {
                space.favoriteTabGroups?.remove(at: favoriteIndex)
            }
            modelContext.delete(group)
        }
    }
}
