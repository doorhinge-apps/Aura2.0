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
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([SpaceData.self])
        return try! ModelContainer(for: schema)
    }()

    var body: some Scene {
        WindowGroup(id: "mainWindow") {
            let storageManager = StorageManager()
            let uiViewModel = UIViewModel()
            let tabsManager = TabsManager()
            let settingsManager = SettingsManager()

            ContentContainerView()
                .ignoresSafeArea(edges: .all)
                .environmentObject(storageManager)
                .environmentObject(uiViewModel)
                .environmentObject(tabsManager)
                .environmentObject(settingsManager)
                .focusedSceneObject(storageManager)
                .focusedSceneObject(uiViewModel)
        }
        .modelContainer(sharedModelContainer)
        .commands { SceneCommands() }
    }
}


private struct SceneCommands: Commands {
    @Environment(\.modelContext) private var modelContext
    
    @FocusedObject private var storageManager: StorageManager?
    @FocusedObject private var uiViewModel:    UIViewModel?

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button {
                uiViewModel?.showCommandBar.toggle()
            } label: {
                Label("New Tab", systemImage: "plus.square.on.square")
            }.keyboardShortcut("t", modifiers: .command)
            
            Button {
                guard
                    let sm  = storageManager,
                    let tab = sm.currentTabs.first?.first?.storedTab
                else { return }
                
                withAnimation {
                    uiViewModel?.currentSelectedTab =
                    sm.closeTab(tabObject: tab, tabType: tab.tabType)?.id ?? ""
                }
            } label: {
                Label("Close Tab", systemImage: "rectangle.badge.xmark")
            }.keyboardShortcut("w", modifiers: .command)
            
            Divider()
            
            Button {
                guard
                    let sm  = storageManager,
                    let tab = sm.currentTabs.first?.first?.storedTab
                else { return }
                
                if storageManager?.currentTabs.first?.first?.tabType == .favorites {
                    withAnimation {
                        sm.updateTabType(for: tab, to: .primary, modelContext: modelContext)
                    }
                }
                else {
                    withAnimation {
                        sm.updateTabType(for: tab, to: .favorites, modelContext: modelContext)
                    }
                }
            } label: {
                Label(storageManager?.currentTabs.first?.first?.tabType == .favorites ? "Unfavorite": "Favorite", systemImage: storageManager?.currentTabs.first?.first?.tabType == .favorites ? "star.fill": "star")
            }
            
            Button {
                guard
                    let sm  = storageManager,
                    let tab = sm.currentTabs.first?.first?.storedTab
                else { return }
                
                if storageManager?.currentTabs.first?.first?.tabType == .pinned {
                    withAnimation {
                        sm.updateTabType(for: tab, to: .primary, modelContext: modelContext)
                    }
                }
                else {
                    withAnimation {
                        sm.updateTabType(for: tab, to: .pinned, modelContext: modelContext)
                    }
                }
            } label: {
                Label(storageManager?.currentTabs.first?.first?.tabType == .pinned ? "Unpin": "Pin", systemImage: storageManager?.currentTabs.first?.first?.tabType == .pinned ? "pin.fill": "pin")
            }
        }
    }
}

