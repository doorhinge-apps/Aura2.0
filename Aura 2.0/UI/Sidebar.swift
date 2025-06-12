//
// Aura 2.0
// Sidebar.swift
//
// Created on 6/11/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import SwiftData

struct Sidebar: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @StateObject var tabsManager = TabsManager()
    
    @Environment(\.modelContext) private var modelContext
    @Query private var spaces: [SpaceData]
    
    var body: some View {
        VStack {
            TabView(selection: $storageManager.selectedSpace) {
                ForEach(spaces, id:\.id) { space in
                    ScrollView {
                        VStack {
                            if let selectedSpace = storageManager.selectedSpace {
                                ForEach(selectedSpace.primaryTabs, id:\.self) { tab in
                                    Button {
                                        Task {
                                            await storageManager.selectOrLoadTab(tabObject: tab)
                                        }
                                    } label: {
                                        ZStack {
                                            HStack {
                                                LoadingAnimations(size: 10, borderWidth: 2)
                                                
                                                Text(tabsManager.linksWithTitles[tab.url] ?? tab.url)
                                                    .lineLimit(1)
                                                    .onAppear {
                                                        Task {
                                                            await tabsManager.fetchTitlesIfNeeded(for: [tab.url])
                                                        }
                                                    }
                                                
                                                Spacer()
                                                
                                                Button {
                                                    storageManager.closeTab(tabObject: tab, tabType: .primary)
                                                } label: {
                                                    Image(systemName: "xmark")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }.tabViewStyle(.page)
        }.frame(width: uiViewModel.sidebarWidth)
    }
}

