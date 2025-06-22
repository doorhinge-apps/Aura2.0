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
        let schema = Schema([SpaceData.self, StoredTab.self])
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
//        .commands { SceneCommands() }
        .commands {
            CommandsBridge()
        }
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

    let selectedTabID: String

    var body: some Commands {
        CommandGroup(after: .newItem) {
            let currentTab = storageManager?.currentTabs.first?.first?.storedTab

            Button {
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
    }
}
