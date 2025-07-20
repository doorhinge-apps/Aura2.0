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
import UniformTypeIdentifiers

struct TabList: View {
    //@Namespace var namespace
    @Environment(\.namespace) var namespace
    @Query(sort: \SpaceData.spaceOrder) var spaces: [SpaceData]
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject var mobileTabs: MobileTabsModel
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    
    @Binding var selectedSpaceIndex: Int
    
    @FocusState.Binding var newTabFocus: Bool
    
    // @StateObject private var snapshotRefresher = SnapshotRefresher() // Not needed for basic implementation
    
    @State var geo: GeometryProxy
    
    @State var topZIndexTab: BrowserTab?
    
    @State var delayLoading: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 60)
            
            if delayLoading {
                LazyVGrid(
                    columns: Array(repeating: GridItem(spacing: 5), count: Int(mobileTabs.gridColumnCount)), content: {
                        ForEach(currentTabsForSelectedSection(), id: \.id) { tab in
                                
                                let offset = mobileTabs.offsets[tab.id, default: .zero]
                                WebPreview(namespace: namespace, url: tab.storedTab.url, geo: geo, tab: tab, browseForMeTabs: $mobileTabs.browseForMeTabs)
                                    .rotationEffect(Angle(degrees: mobileTabs.tilts[tab.id, default: 0.0]))
                                    .offset(x: offset.width)
                                    .overlay(content: {
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.white.opacity(0.0001))
                                            .onTapGesture {
                                                mobileTabs.newTabFromTab = false
                                                
                                                if newTabFocus {
                                                    newTabFocus = false
                                                }
                                                else {
                                                    withAnimation {
                                                        uiViewModel.currentSelectedTab = tab.storedTab.id
                                                        mobileTabs.fullScreenWebView = true
                                                    }
                                                }
                                            }
                                    })
                                    .zIndex(topZIndexTab == tab ? 100: 1)
                                    .gesture(
                                        DragGesture(minimumDistance: 50)
                                            .onChanged { gesture in
                                                if newTabFocus {
                                                    newTabFocus = false
                                                }
                                                else {
                                                    handleDragChange(gesture, for: tab.id)
                                                }
                                                topZIndexTab = tab
                                            }
                                            .onEnded { gesture in
                                                if newTabFocus {
                                                    newTabFocus = false
                                                }
                                                else {
                                                    handleDragEnd(gesture, for: tab.id)
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                                    topZIndexTab = nil
                                                }
                                            }
                                    )
                                    .contextMenu(menuItems: {
                                        Button(action: {
                                            UIPasteboard.general.string = tab.storedTab.url
                                        }, label: {
                                            Label("Copy URL", systemImage: "link")
                                        })
                                        
                                        if true { // TODO: Add hideBrowseForMe setting to SettingsManager
                                            Button(action: {
                                                if mobileTabs.browseForMeTabs.contains(tab.id.description) {
                                                    mobileTabs.browseForMeTabs.removeAll { $0 == tab.id.description }
                                                }
                                                else {
                                                    mobileTabs.browseForMeTabs.append(tab.id.description)
                                                }
                                            }, label: {
                                                Label(mobileTabs.browseForMeTabs.contains(tab.id.description) ? "Disable Browse for Me": "Browse for Me", systemImage: "face.smiling")
                                            })
                                        }
                                    })
                                    .onDrag {
                                        self.mobileTabs.draggedTab = tab
                                        return NSItemProvider(object: tab.storedTab.url as NSString)
                                    }
                                    .onDrop(of: [.text], delegate: AlternateDropViewDelegate(destinationItem: tab, allTabs: currentTabsBinding(), draggedItem: $mobileTabs.draggedTab))
                                    // Tab changes are automatically saved by StorageManager
                                
                            }
                    })
                .padding(10)
            }
            
            Spacer()
                .frame(height: 120)
        }.onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                delayLoading = true
            }
        }
    }
    
    private func handleDragChange(_ gesture: DragGesture.Value, for id: UUID) {
        mobileTabs.offsets[id] = gesture.translation
        mobileTabs.zIndexes[id] = 100
        var tilt = min(Double(abs(gesture.translation.width)) / 20, 15)
        if gesture.translation.width < 0 {
            tilt *= -1
        }
        mobileTabs.tilts[id] = tilt
        
        mobileTabs.closeTabScrollDisabledCounter = abs(Int(gesture.translation.width))
    }
    
    private func handleDragEnd(_ gesture: DragGesture.Value, for id: UUID) {
        mobileTabs.zIndexes[id] = 1
        if abs(gesture.translation.width) > 100 {
            withAnimation {
                if gesture.translation.width < 0 {
                    mobileTabs.offsets[id] = CGSize(width: -500, height: 0)
                } else {
                    mobileTabs.offsets[id] = CGSize(width: 500, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        removeItem(id)
                    }
                }
            }
        } else {
            withAnimation {
                mobileTabs.offsets[id] = .zero
                mobileTabs.tilts[id] = 0.0
            }
        }
        
        mobileTabs.closeTabScrollDisabledCounter = 0
    }
    
    private func saveTabs() {
        if UserDefaults.standard.integer(forKey: "savedSelectedSpaceIndex") > spaces.count - 1 {
            selectedSpaceIndex = 0
        }
        
        if spaces.count > selectedSpaceIndex {
            // Save changes to SwiftData model
            try? modelContext.save()
        }
    }
    
    private func removeItem(_ id: UUID) {
        mobileTabs.browseForMeTabs.removeAll { $0 == id.description }
        
        // Find and remove the tab from the current tabs
        let allTabs = currentTabsForSelectedSection()
        if let tabToRemove = allTabs.first(where: { $0.id == id }) {
            // Remove from SwiftData
            modelContext.delete(tabToRemove.storedTab)
            try? modelContext.save()
        }
        
        withAnimation {
            mobileTabs.offsets.removeValue(forKey: id)
            mobileTabs.tilts.removeValue(forKey: id)
            mobileTabs.zIndexes.removeValue(forKey: id)
        }
    }
    
    // MARK: - Helper Methods
    
    private func currentTabsForSelectedSection() -> [BrowserTab] {
        guard selectedSpaceIndex < spaces.count else { return [] }
        let currentSpace = spaces[selectedSpaceIndex]
        
        switch uiViewModel.currentTabTypeMobile {
        case .primary:
            return currentSpace.primaryTabs.map { storedTab in
                createBrowserTab(from: storedTab)
            }
        case .pinned:
            return currentSpace.pinnedTabs.map { storedTab in
                createBrowserTab(from: storedTab)
            }
        case .favorites:
            return currentSpace.favoriteTabs.map { storedTab in
                createBrowserTab(from: storedTab)
            }
        }
    }
    
    private func createBrowserTab(from storedTab: StoredTab) -> BrowserTab {
        // Create a placeholder WebPageFallback - actual loading happens in fullscreen
        let webPage = WebPageFallback()
        
        return BrowserTab(
            lastActiveTime: storedTab.timestamp,
            tabType: storedTab.tabType,
            page: webPage,
            storedTab: storedTab
        )
    }
    
    private func currentTabsBinding() -> Binding<[BrowserTab]> {
        return Binding(
            get: { self.currentTabsForSelectedSection() },
            set: { _ in
                // Tab reordering will be handled by the drop delegate
                // and saved through StorageManager
            }
        )
    }
}

