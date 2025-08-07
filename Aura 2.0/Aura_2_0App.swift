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
#if targetEnvironment(macCatalyst)
import AppKit
#endif

@main
struct Aura_2_0App: App {
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([SpaceData.self, TabGroup.self, TabRow.self, StoredTab.self])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
//        return try! ModelContainer(for: schema)
        do {
            var container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup(id: "mainWindow") {
            let storageManager = StorageManager()
            let uiViewModel = UIViewModel()
            let tabsManager = TabsManager()
            let settingsManager = SettingsManager()

            ContentContainerView()
                .environmentObject(storageManager)
                .environmentObject(uiViewModel)
                .environmentObject(tabsManager)
                .environmentObject(settingsManager)
                .focusedSceneObject(storageManager)
                .focusedSceneObject(uiViewModel)
                .onAppear() { hideTitleBarOnCatalyst() }
        }
        .modelContainer(for: [SpaceData.self, TabGroup.self, TabRow.self, StoredTab.self], inMemory: false, isAutosaveEnabled: true, isUndoEnabled: true)
        .commands {
            CommandsBridge()
        }
    }
    
    func hideTitleBarOnCatalyst() {
#if targetEnvironment(macCatalyst)
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.titlebar?.titleVisibility = .hidden
#endif
    }
}

private struct CommandsBridge: Commands {
    @FocusedObject private var uiViewModel: UIViewModel?

    var body: some Commands {
        SceneCommands(selectedTabID: uiViewModel?.currentSelectedTab ?? "none")
    }
}

private struct SceneCommands: Commands {
    @Environment(\.modelContext) private var modelContext
    @FocusedObject private var storageManager: StorageManager?
    @FocusedObject private var uiViewModel: UIViewModel?
    @FocusedObject private var settingsManager: SettingsManager?

    let selectedTabID: String

    var body: some Commands {
        CommandGroup(after: .newItem) {
            let currentTab = storageManager?.currentTabs.first?.first?.storedTab

            Button {
                uiViewModel?.commandBarText = ""
                uiViewModel?.searchSuggestions = []
                
                uiViewModel?.showCommandBar.toggle()
            } label: {
                Label("New Tab", systemImage: "plus.square.on.square")
            }.keyboardShortcut("t", modifiers: .command)

            if let tab = currentTab {
                Button {
                    withAnimation {
                        uiViewModel?.currentSelectedTab =
                            storageManager?.closeTab(tabObject: tab, tabType: tab.tabType)?.id ?? ""
                    }
                } label: {
                    Label("Close Tab", systemImage: "rectangle.badge.xmark")
                }.keyboardShortcut("w", modifiers: .command)

                Divider()

                Button {
                    withAnimation {
                        storageManager?.updateTabType(
                            for: tab,
                            to: tab.tabType == .favorites ? .primary : .favorites,
                            modelContext: modelContext
                        )
                    }
                } label: {
                    Label(tab.tabType == .favorites ? "Unfavorite" : "Favorite",
                          systemImage: tab.tabType == .favorites ? "star.fill" : "star")
                }

                Button {
                    withAnimation {
                        storageManager?.updateTabType(
                            for: tab,
                            to: tab.tabType == .pinned ? .primary : .pinned,
                            modelContext: modelContext
                        )
                    }
                } label: {
                    Label(tab.tabType == .pinned ? "Unpin" : "Pin",
                          systemImage: tab.tabType == .pinned ? "pin.fill" : "pin")
                }
            }
        }
        
//        CommandGroup(after: .sidebar) {
        CommandGroup(replacing: .sidebar) {
            Button {
                withAnimation(.easeInOut) {
                    uiViewModel?.showSidebar.toggle()
                }
            } label: {
                Label(uiViewModel?.showSidebar ?? false ? "Hide Sidebar": "Show Sidebar",
                      systemImage: settingsManager?.tabsPosition == "right" ? "sidebar.right": "sidebar.left")
            }.keyboardShortcut("s", modifiers: .command)
        }
    }
}
