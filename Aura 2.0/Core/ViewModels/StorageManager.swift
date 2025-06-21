//
// Aura 2.0
// StorageManager.swift
//
// Created on 6/10/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import Combine
import WebKit
import SwiftData

class StorageManager: ObservableObject {
//    @Published var currentTabs: [[BrowserTab]]
//    init() {
//        self.currentTabs = []
//
//        self.currentTabs.append([
//            makeTab(url: "https://apple.com"),
//            makeTab(url: "https://figma.com")
//        ])
//
//        self.currentTabs.append([
//            makeTab(url: "https://arc.net"),
//            makeTab(url: "https://google.com"),
//            makeTab(url: "https://thebrowser.company")
//        ])
//
//        self.currentTabs.append([
//            makeTab(url: "https://doorhingeapps.com")
//        ])
//    }
    
    private func makeTab(url: String) -> BrowserTab {
            let page = WebPage()
            var request = URLRequest(url: URL(string: url)!)
            request.attribution = .user
            page.load(request)

        let stored = StoredTab(id: createStoredTabID(url: url),
                               timestamp: .now,
                               url: url,
                               orderIndex: 0,
                               tabType: .primary)
            let tab = BrowserTab(lastActiveTime: .now, tabType: .primary, page: page, storedTab: stored)
            return tab
        }
    
    @StateObject var settingManager = SettingsManager()
    
    @Published var selectedSpace: SpaceData?
    // Tabs currently loaded in the background
    @Published var loadedTabs: [BrowserTab] = []
    
    // Tabs currently open
    // This update will allow for split view. This will work with nested arrays.
    // Each array is a row. The number of items in each array is the number of collumns.
    // Aura will load all of these at the same time
    @Published var currentTabs: [[BrowserTab]] = []
    
    
//    @Published var currentTabs: [[BrowserTab]] = [
//        BrowserTab(lastActiveTime: Date.now, tabType: .primary, page: <#T##WebPage#>, storedTab: StoredTab(timestamp: Date.now, url: "https://apple.com", tabType: .primary))
//    ]
    
    @Published var splitViewTabs: [SplitViewTab] = []
    
    func loadTabFromStorage(tabObject: StoredTab) {
        let newWebPage = WebPage()
        var request = URLRequest(url: URL(string: tabObject.url)!)
        request.attribution = .user
        newWebPage.load(request)
        
        loadedTabs.append(
            BrowserTab(
                lastActiveTime: Date.now,
                tabType: tabObject.tabType,
                page: newWebPage,
                storedTab: tabObject
            )
        )
    }
    
    func selectOrLoadTab(tabObject: StoredTab) async {
        if let index = splitViewTabs.firstIndex(where: { $0.mainTab == tabObject }) {
            splitViewTabs[index].subTabLayout = currentTabs
        } else if let existingTab = loadedTabs.first(where: { $0.storedTab == tabObject }) {
            currentTabs = [[existingTab]]
        } else {
            let newWebPage = WebPage()
            var request = URLRequest(url: URL(string: tabObject.url)!)
            request.attribution = .user
            newWebPage.load(request)
            
            
            do {
                try await newWebPage.callJavaScript(
                    String(
                        """
                                (function() {
                                  var style = document.createElement('style');
                                  style.textContent = `.headerTitle {color: black!important;}`;
                                  document.head.appendChild(style);
                                })();
                        """
                    )
                )
            } catch {
                print("JavaScript injection failed: \(error)")
            }
                
            
            
            let newTab = BrowserTab(
                lastActiveTime: Date.now,
                tabType: .primary,
                page: newWebPage,
                storedTab: tabObject
            )
            currentTabs = [[newTab]]
            loadedTabs.append(newTab)
        }
        
        if loadedTabs.count >= Int(settingManager.preloadingWebsites) {
            loadedTabs.removeFirst()
        }
    }
    
    func newTab(unformattedString: String, space: SpaceData, modelContext: ModelContext) -> StoredTab {
        let formattedURL = formatURL(from: unformattedString)
        let page = WebPage()
        var request = URLRequest(url: URL(string: formattedURL)!)
        request.attribution = .user
        page.load(request)
        
        let newOrder = space.primaryTabs.count
        let storedTabObject = StoredTab(
            id: createStoredTabID(url: formattedURL),
            timestamp: Date.now,
            url: formattedURL,
            orderIndex: newOrder,
            tabType: .primary,
            parentSpace: space
        )
        print("Created tab \(storedTabObject.id) with orderIndex \(newOrder)")

        // Add to the space's storedTabs and persist
        modelContext.insert(storedTabObject)
        space.tabs.append(storedTabObject)
        try? modelContext.save()
        
        let createdTab = BrowserTab(lastActiveTime: Date.now, tabType: .primary, page: page, storedTab: storedTabObject)

        currentTabs = [[createdTab]]
        
        appendAndRemove(addingTab: createdTab)
        
        return storedTabObject
    }
    
    func closeTab(tabObject: StoredTab, tabType: TabType) -> StoredTab? {
        switch tabType {
        case .primary:
            guard let space = selectedSpace,
                  let removedIdx = space.primaryTabs.firstIndex(where: { $0.id == tabObject.id })
            else { return nil }
            space.tabs.remove(at: removedIdx)
            for (i, tab) in space.primaryTabs.enumerated() { tab.orderIndex = i }
            let nextIdx = removedIdx, prevIdx = removedIdx - 1
            let replacement: StoredTab? = space.primaryTabs.indices.contains(nextIdx)
                ? space.primaryTabs[nextIdx]
                : (space.primaryTabs.indices.contains(prevIdx) ? space.primaryTabs[prevIdx] : nil)
            if let tab = replacement {
                Task { await selectOrLoadTab(tabObject: tab) }
            } else {
                currentTabs = [[]]
            }
            return replacement

        case .pinned:
            guard let space = selectedSpace,
                  let removedIdx = space.pinnedTabs.firstIndex(where: { $0.id == tabObject.id })
            else { return nil }
            space.tabs.remove(at: removedIdx)
            for (i, tab) in space.pinnedTabs.enumerated() { tab.orderIndex = i }
            let nextPinned = removedIdx, prevPinned = removedIdx - 1
            let replacementPinned: StoredTab? = space.pinnedTabs.indices.contains(nextPinned)
                ? space.pinnedTabs[nextPinned]
                : (space.pinnedTabs.indices.contains(prevPinned) ? space.pinnedTabs[prevPinned] : nil)
            if let tab = replacementPinned {
                Task { await selectOrLoadTab(tabObject: tab) }
            } else {
                currentTabs = [[]]
            }
            return replacementPinned

        case .favorites:
            guard let space = selectedSpace,
                  let removedIdx = space.favoriteTabs.firstIndex(where: { $0.id == tabObject.id })
            else { return nil }
            space.tabs.remove(at: removedIdx)
            for (i, tab) in space.favoriteTabs.enumerated() { tab.orderIndex = i }
            let nextFav = removedIdx, prevFav = removedIdx - 1
            let replacementFav: StoredTab? = space.favoriteTabs.indices.contains(nextFav)
                ? space.favoriteTabs[nextFav]
                : (space.favoriteTabs.indices.contains(prevFav) ? space.favoriteTabs[prevFav] : nil)
            if let tab = replacementFav {
                Task { await selectOrLoadTab(tabObject: tab) }
            } else {
                currentTabs = [[]]
            }
            return replacementFav
        }
    }

    
    func appendAndRemove(addingTab: BrowserTab) {
        loadedTabs.append(addingTab)
        
        if loadedTabs.count >= Int(settingManager.preloadingWebsites) {
            loadedTabs.removeFirst()
        }
    }
    
    func initializeSelectedSpace(from spaces: [SpaceData], modelContext: ModelContext) {
        if spaces.isEmpty {
            let newSpace = SpaceData(
                spaceIdentifier: UUID().uuidString,
                spaceName: "Untitled",
                isIncognito: false,
                spaceBackgroundColors: ["8041E6", "A0F2FC"],
                textColor: "ffffff"
            )
            modelContext.insert(newSpace)
            try? modelContext.save()
            selectedSpace = newSpace
        } else {
            selectedSpace = spaces.first
        }
    }
    
    func appLaunchTasks(allTabs: [StoredTab]) {
        clearOldTabs(allTabs: allTabs)
    }
    
    func clearOldTabs(allTabs: [StoredTab]) -> [StoredTab] {
        let closeWindowDays = UserDefaults.standard.integer(forKey: "tabCloseWindow")
        let now = Date()
        let calendar = Calendar.current

        return allTabs.filter { tab in
            guard let cutoff = calendar.date(byAdding: .day, value: -closeWindowDays, to: now) else {
                return true
            }
            return tab.timestamp >= cutoff
        }
    }

    /// Update a tab's URL across all in-memory representations and persist the change.
    @MainActor
    func updateURL(for tabID: UUID, newURL: String, modelContext: ModelContext) {
        // Update currently displayed tabs
        for rowIdx in currentTabs.indices {
            for colIdx in currentTabs[rowIdx].indices where currentTabs[rowIdx][colIdx].id == tabID {
                currentTabs[rowIdx][colIdx].storedTab.url = newURL
            }
        }

        // Update any preloaded tabs
        for idx in loadedTabs.indices where loadedTabs[idx].id == tabID {
            loadedTabs[idx].storedTab.url = newURL
        }

        // Update tabs stored in split view containers
        let storedID = currentTabs.flatMap { $0 }.first(where: { $0.id == tabID })?.storedTab.id
        for idx in splitViewTabs.indices where splitViewTabs[idx].mainTab.id == storedID {
            splitViewTabs[idx].mainTab.url = newURL
        }

        try? modelContext.save()
    }
    
    @MainActor
    func updateTabType(for storedTab: StoredTab, to newType: TabType, modelContext: ModelContext) {
        storedTab.tabType = newType
        
        for rowIdx in currentTabs.indices {
            for colIdx in currentTabs[rowIdx].indices where currentTabs[rowIdx][colIdx].storedTab.id == storedTab.id {
                currentTabs[rowIdx][colIdx].tabType = newType
                currentTabs[rowIdx][colIdx].storedTab.tabType = newType
            }
        }
        
        try? modelContext.save()
    }
}

