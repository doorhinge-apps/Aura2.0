//
// Aura
// TabList.swift
//
// Created by Reyna Myers on 26/10/24
//
// Copyright ©2024 DoorHinge Apps.
//


import SwiftUI
import SwiftData

struct TabList: View {
    @Environment(\.namespace) var namespace
    
    @Environment(\.modelContext) private var modelContext
    @Query private var spaces: [SpaceData]
    
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var mobileTabs: MobileTabsModel
    
    @FocusState.Binding var newTabFocus: Bool
    
    @StateObject private var snapshotRefresher = SnapshotRefresher()
    
    @State var geo: GeometryProxy
    
    @State var topZIndexTab: TabGroup?
    @State var delayLoading: Bool = false
    
    // Tab display state
    @State var selectedTabsSection: TabLocations = .tabs
    @State var gridColumnCount: Double = 2.0
    
    // Tab interaction state
    @State var offsets: [String: CGSize] = [:]
    @State var tilts: [String: Double] = [:]
    @State var closeTabScrollDisabledCounter = 0
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 60)
            
            if delayLoading {
                LazyVGrid(
                    columns: Array(repeating: GridItem(spacing: 5), count: Int(gridColumnCount)), content: {
                        ForEach(currentTabGroups, id: \.id) { tabGroup in
                            if let firstTab = tabGroup.tabRows?.first?.tabs?.first {
                                let offset = offsets[tabGroup.id, default: .zero]
                                
                                WebPreview(
                                    namespace: namespace, 
                                    url: firstTab.url, 
                                    geo: geo, 
                                    tab: tabGroup, 
                                    browseForMeTabs: .constant([])
                                )
                                .rotationEffect(Angle(degrees: tilts[tabGroup.id, default: 0.0]))
                                .offset(x: offset.width)
                                .overlay(content: {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white.opacity(0.0001))
                                        .onTapGesture {
                                            if newTabFocus {
                                                newTabFocus = false
                                            } else {
                                                handleTabTap(tabGroup: tabGroup, storedTab: firstTab)
                                            }
                                        }
                                })
                                .zIndex(topZIndexTab == tabGroup ? 100: 1)
                                .gesture(
                                    DragGesture(minimumDistance: 50)
                                        .onChanged { gesture in
                                            if newTabFocus {
                                                newTabFocus = false
                                            } else {
                                                handleDragChange(gesture, for: tabGroup.id)
                                            }
                                            topZIndexTab = tabGroup
                                        }
                                        .onEnded { gesture in
                                            if newTabFocus {
                                                newTabFocus = false
                                            } else {
                                                handleDragEnd(gesture, for: tabGroup.id, tabGroup: tabGroup)
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                                topZIndexTab = nil
                                            }
                                        }
                                )
                                .contextMenu(menuItems: {
                                    Button(action: {
                                        UIPasteboard.general.string = firstTab.url
                                    }, label: {
                                        Label("Copy URL", systemImage: "link")
                                    })
                                })
                            }
                        }
                    })
                .padding(10)
            }
            
            Spacer()
                .frame(height: 120)
        }
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                delayLoading = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentTabGroups: [TabGroup] {
        guard let space = storageManager.selectedSpace else { return [] }
        
        switch selectedTabsSection {
        case .tabs:
            return space.primaryTabGroups ?? []
        case .pinned:
            return space.pinnedTabGroups ?? []
        case .favorites:
            return space.favoriteTabGroups ?? []
        }
    }
    
    // MARK: - Tab Selection
    
    private func handleTabTap(tabGroup: TabGroup, storedTab: StoredTab) {
        Task {
            // Use StorageManager to properly load the tab
            await storageManager.selectOrLoadTab(tabObject: storedTab)
            
            // Update UI state to show fullscreen webview in TabOverview
            await MainActor.run {
                // Set the mobileTabs flags to trigger WebsiteView display in TabOverview
                mobileTabs.webURL = storedTab.url
                mobileTabs.fullScreenWebView = true
            }
        }
    }
    
    // MARK: - Drag Gestures
    
    private func handleDragChange(_ gesture: DragGesture.Value, for id: String) {
        offsets[id] = gesture.translation
        var tilt = min(Double(abs(gesture.translation.width)) / 20, 15)
        if gesture.translation.width < 0 {
            tilt *= -1
        }
        tilts[id] = tilt
        
        closeTabScrollDisabledCounter = abs(Int(gesture.translation.width))
    }
    
    private func handleDragEnd(_ gesture: DragGesture.Value, for id: String, tabGroup: TabGroup) {
        if abs(gesture.translation.width) > 100 {
            withAnimation {
                if gesture.translation.width < 0 {
                    offsets[id] = CGSize(width: -500, height: 0)
                } else {
                    offsets[id] = CGSize(width: 500, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        let replacement = storageManager.closeTabGroup(tabGroup: tabGroup, modelContext: modelContext, selectNext: true)
                        if let replacementTab = replacement {
                            uiViewModel.currentSelectedTab = replacementTab.id
                        }
                    }
                }
            }
        } else {
            withAnimation {
                offsets[id] = .zero
                tilts[id] = 0.0
            }
        }
        
        closeTabScrollDisabledCounter = 0
    }
    
    private func removeItem(_ id: String) {
        withAnimation {
            offsets.removeValue(forKey: id)
            tilts.removeValue(forKey: id)
        }
    }
}

