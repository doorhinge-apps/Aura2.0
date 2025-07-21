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
    
    @EnvironmentObject var mobileTabs: MobileTabsModel
    
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
//    @Binding var selectedSpaceIndex: Int
    
    @FocusState.Binding var newTabFocus: Bool
    
    @StateObject private var snapshotRefresher = SnapshotRefresher()
    
    @State var geo: GeometryProxy
    
    @State var topZIndexTab: TabGroup?
    
    @State var delayLoading: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 60)
            
            if delayLoading {
                LazyVGrid(
                    columns: Array(repeating: GridItem(spacing: 5), count: Int(mobileTabs.gridColumnCount)), content: {
                        ForEach(
                            (mobileTabs.selectedTabsSection == .tabs ?
                             storageManager.selectedSpace?.primaryTabGroups: mobileTabs.selectedTabsSection == .pinned ?
                             storageManager.selectedSpace?.pinnedTabGroups:
                                storageManager.selectedSpace?.favoriteTabGroups) ?? [],
                            id: \.id) { tab in
                                
                                let offset = mobileTabs.offsets[UUID(uuidString: tab.id) ?? UUID(), default: .zero]
                                if let thing = tab.tabRows?.first?.tabs?.first {
                                    WebPreview(namespace: namespace, url: thing.url, geo: geo, tab: tab, browseForMeTabs: $mobileTabs.browseForMeTabs)
                                        .rotationEffect(Angle(degrees: mobileTabs.tilts[UUID(uuidString: tab.id) ?? UUID(), default: 0.0]))
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
                                                        Task {
                                                            await storageManager.selectOrLoadTab(tabObject: thing)
                                                        }
                                                        withAnimation {
                                                            mobileTabs.webURL = thing.url
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
                                                        handleDragEnd(gesture, for: tab.id, tab: tab)
                                                    }
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                                        topZIndexTab = nil
                                                    }
                                                }
                                        )
                                        .contextMenu(menuItems: {
                                            Button(action: {
                                                UIPasteboard.general.string = thing.url
                                            }, label: {
                                                Label("Copy URL", systemImage: "link")
                                            })
                                            
                                            if !mobileTabs.settings.hideBrowseForMe {
                                                Button(action: {
                                                    if mobileTabs.browseForMeTabs.contains(tab.id) {
                                                        mobileTabs.browseForMeTabs.removeAll { $0 == tab.id }
                                                    }
                                                    else {
                                                        mobileTabs.browseForMeTabs.append(tab.id)
                                                    }
                                                }, label: {
                                                    Label(mobileTabs.browseForMeTabs.contains(tab.id) ? "Disable Browse for Me": "Browse for Me", systemImage: "face.smiling")
                                                })
                                            }
                                        })
//                                        .onDrag {
//                                            self.mobileTabs.draggedTab = tab
//                                            return NSItemProvider(object: thing.url as NSString)
//                                        }
                                    // TODO: - Add back drag and drop support
                                    //                                    .onDrop(of: [.text], delegate: AlternateDropViewDelegate(destinationItem: tab, allTabs: mobileTabs.selectedTabsSection == .tabs ? $mobileTabs.tabs: mobileTabs.selectedTabsSection == .pinned ? $mobileTabs.pinnedTabs: $mobileTabs.favoriteTabs, draggedItem: $mobileTabs.draggedTab))
                                }
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
    
    private func handleDragChange(_ gesture: DragGesture.Value, for id: String) {
        mobileTabs.offsets[UUID(uuidString: id) ?? UUID()] = gesture.translation
        mobileTabs.zIndexes[UUID(uuidString: id) ?? UUID()] = 100
        var tilt = min(Double(abs(gesture.translation.width)) / 20, 15)
        if gesture.translation.width < 0 {
            tilt *= -1
        }
        mobileTabs.tilts[UUID(uuidString: id) ?? UUID()] = tilt
        
        mobileTabs.closeTabScrollDisabledCounter = abs(Int(gesture.translation.width))
    }
    
    private func handleDragEnd(_ gesture: DragGesture.Value, for id: String, tab: TabGroup) {
        mobileTabs.zIndexes[UUID(uuidString: id) ?? UUID()] = 1
        if abs(gesture.translation.width) > 100 {
            withAnimation {
                if gesture.translation.width < 0 {
                    mobileTabs.offsets[UUID(uuidString: id) ?? UUID()] = CGSize(width: -500, height: 0)
                } else {
                    mobileTabs.offsets[UUID(uuidString: id) ?? UUID()] = CGSize(width: 500, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        let replacement = storageManager.closeTabGroup(tabGroup: tab, modelContext: modelContext)
//                            .closeTabGroup(tabGroup: tabGroup, modelContext: modelContext)
                        uiViewModel.currentSelectedTab = replacement?.id ?? ""
                    }
                }
            }
        } else {
            withAnimation {
                mobileTabs.offsets[UUID(uuidString: id) ?? UUID()] = .zero
                mobileTabs.tilts[UUID(uuidString: id) ?? UUID()] = 0.0
            }
        }
        
        mobileTabs.closeTabScrollDisabledCounter = 0
    }
    
//    private func saveTabs() {
//        if UserDefaults.standard.integer(forKey: "savedSelectedSpaceIndex") > spaces.count - 1 {
//            selectedSpaceIndex = 0
//        }
//        
//        if spaces.count > selectedSpaceIndex {
//            // Extracting URLs from tabs, pinnedTabs, and favoriteTabs arrays
//            let extractedTabUrls = mobileTabs.tabs.map { $0.url }
//            let extractedPinnedUrls = mobileTabs.pinnedTabs.map { $0.url }
//            let extractedFavoriteUrls = mobileTabs.favoriteTabs.map { $0.url }
//            
//            // Updating the corresponding space with the extracted URLs
//            spaces[selectedSpaceIndex].tabUrls = extractedTabUrls
//            spaces[selectedSpaceIndex].pinnedUrls = extractedPinnedUrls
//            spaces[selectedSpaceIndex].favoritesUrls = extractedFavoriteUrls
//        }
//    }
    
    private func removeItem(_ id: String) {
//        mobileTabs.browseForMeTabs.removeAll { $0 == id.description }
//        
//        switch mobileTabs.selectedTabsSection {
//        case .tabs:
//            if let index = mobileTabs.tabs.firstIndex(where: { $0.id == id }) {
//                mobileTabs.tabs.remove(at: index)
//                spaces[selectedSpaceIndex].tabUrls.remove(at: index)
//            }
//        case .pinned:
//            if let index = mobileTabs.pinnedTabs.firstIndex(where: { $0.id == id }) {
//                mobileTabs.pinnedTabs.remove(at: index)
//                spaces[selectedSpaceIndex].pinnedUrls.remove(at: index)
//            }
//        case .favorites:
//            if let index = mobileTabs.favoriteTabs.firstIndex(where: { $0.id == id }) {
//                mobileTabs.favoriteTabs.remove(at: index)
//                spaces[selectedSpaceIndex].favoritesUrls.remove(at: index)
//            }
//        }
        
        
        withAnimation {
            mobileTabs.offsets.removeValue(forKey: UUID(uuidString: id) ?? UUID())
            mobileTabs.tilts.removeValue(forKey: UUID(uuidString: id) ?? UUID())
            mobileTabs.zIndexes.removeValue(forKey: UUID(uuidString: id) ?? UUID())
        }
    }
}

