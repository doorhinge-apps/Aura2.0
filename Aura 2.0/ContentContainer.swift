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

let automaticColor = Color("Automatic")

struct ContentContainerView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.modelContext) private var modelContext
    @Query private var spaces: [SpaceData]
    
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    @State private var screenStateManager = ScreenStateManager()
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                Color.clear
                    .onAppear() {
                        screenStateManager.defineBoundsAndUpdate(appWindowWidth: geo.size.width, appWindowHeight: geo.size.height)
                        print("isFullScreen:")
                        print(screenStateManager.isFullScreen)
                        print(screenStateManager.screenWidth)
                        print(screenStateManager.screenHeight)
                        print(screenStateManager.appWindowWidth ?? 0)
                        print(screenStateManager.appWindowHeight ?? 0)
                    }
                    .onChange(of: geo.size) { oldValue, newValue in
                        screenStateManager.defineBoundsAndUpdate(appWindowWidth: newValue.width, appWindowHeight: newValue.height)
                        print("isFullScreen:")
                        print(screenStateManager.isFullScreen)
                        print(screenStateManager.screenWidth)
                        print(screenStateManager.screenHeight)
                        print(screenStateManager.appWindowWidth ?? 0)
                        print(screenStateManager.appWindowHeight ?? 0)
                    }
            }.ignoresSafeArea()
            
            Group {
                if let selected = spaces.first {
                    ZStack {
                        if UIDevice.current.userInterfaceIdiom == .phone {
                            MobileHomepage()
                        }
                        else {
                            ContentView(selectedSpace: selected)
                                .ignoresSafeArea(.container, edges: .all)
                                .modifier(ScrollEdgeDisabledIfAvailable())
                                .modifier(ScrollEdgeIfAvailable())
                                .statusBarHidden(true)
                        }
                    }.onAppear {
                        // MARK: - Clear old tabs
                        let cutoff = Date().addingTimeInterval(-Double(settingsManager.closePrimaryTabsAfter) * 60)
                        
                        for space in spaces {
                            // Clean up old tabs from the new group structure
                            cleanupOldTabsFromGroups(space: space, cutoff: cutoff, modelContext: modelContext)
                            
                            // Clean up old tabs from old structure
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
                        
                        // MARK: - Show command bar on launch
                        if settingsManager.commandBarOnLaunch {
                            uiViewModel.showCommandBar = true
                        }
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
        .environment(screenStateManager)
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
