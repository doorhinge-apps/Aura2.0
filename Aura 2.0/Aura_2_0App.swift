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
    
    @StateObject var storageManager = StorageManager()
    @StateObject var uiViewModel = UIViewModel()
    @StateObject var tabsManager = TabsManager()
    @StateObject var settingsManager = SettingsManager()

    var body: some Scene {
        WindowGroup(id: "mainWindow") {
            ContentContainerView()
                .ignoresSafeArea(edges: .all)
                .environmentObject(storageManager)
                .environmentObject(uiViewModel)
                .environmentObject(tabsManager)
                .environmentObject(settingsManager)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button {
                    uiViewModel.showCommandBar.toggle()
                } label: {
                    Label("New Tab", systemImage: "plus.square.on.square")
                }.keyboardShortcut("t", modifiers: .command)
                
                Button {
                    if storageManager.currentTabs[0][0].storedTab != nil {
//                        storageManager.closeTab(tabObject: storageManager.currentTabs[0][0].storedTab, tabType: storageManager.currentTabs[0][0].storedTab.tabType)
                        withAnimation {
                            uiViewModel.currentSelectedTab = storageManager.closeTab(tabObject: storageManager.currentTabs[0][0].storedTab, tabType: storageManager.currentTabs[0][0].storedTab.tabType)?.id ?? ""
                        }
                    }
                } label: {
                    Label("Close Tab", systemImage: "rectangle.badge.xmark")
                }.keyboardShortcut("w", modifiers: .command)
            }
            CommandGroup(replacing: .toolbar) {}
        }
        
    }
}
