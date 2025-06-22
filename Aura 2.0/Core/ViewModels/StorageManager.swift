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
        
        let newOrder = space.primaryTabGroups.count
        let storedTabObject = StoredTab(
            id: createStoredTabID(url: formattedURL),
            timestamp: Date.now,
            url: formattedURL,
            orderIndex: 0, // First tab in its group
            tabType: .primary,
            parentSpace: space
        )
        print("Created tab \(storedTabObject.id) with orderIndex \(newOrder)")

        // Create a new TabGroup for this single tab
        let tabGroup = TabGroup(
            timestamp: Date.now,
            tabType: .primary,
            orderIndex: newOrder,
            parentSpace: space
        )
        
        // Add the tab to the group using the nested structure [[StoredTab]]
        tabGroup.addTab(storedTabObject)
        
        // Insert models and update relationships
        modelContext.insert(storedTabObject)
        modelContext.insert(tabGroup)
        space.primaryTabGroups.append(tabGroup)
        space.tabs.append(storedTabObject) // Keep legacy relationship for migration
        
        try? modelContext.save()
        
        let createdTab = BrowserTab(lastActiveTime: Date.now, tabType: .primary, page: page, storedTab: storedTabObject)

        currentTabs = [[createdTab]]
        
        appendAndRemove(addingTab: createdTab)
        
        return storedTabObject
    }
    
    func closeTab(tabObject: StoredTab, tabType: TabType) -> StoredTab? {
        guard let space = selectedSpace else { return nil }
        
        switch tabType {
        case .primary:
            return closeTabFromGroups(tabObject: tabObject, groups: &space.primaryTabGroups, space: space)
        case .pinned:
            return closeTabFromGroups(tabObject: tabObject, groups: &space.pinnedTabGroups, space: space)
        case .favorites:
            return closeTabFromGroups(tabObject: tabObject, groups: &space.favoriteTabGroups, space: space)
        }
    }
    
    private func closeTabFromGroups(tabObject: StoredTab, groups: inout [TabGroup], space: SpaceData) -> StoredTab? {
        // Find the group containing this tab
        for (groupIndex, group) in groups.enumerated() {
            for (rowIndex, row) in group.tabRows.enumerated() {
                if let tabIndex = row.tabs.firstIndex(where: { $0.id == tabObject.id }) {
                    // Remove the tab from its row
                    row.tabs.remove(at: tabIndex)
                    
                    // Clean up empty rows and groups
                    if row.tabs.isEmpty {
                        group.tabRows.remove(at: rowIndex)
                    }
                    
                    if group.tabRows.isEmpty {
                        groups.remove(at: groupIndex)
                    }
                    
                    // Remove from legacy tabs array
                    if let legacyIndex = space.tabs.firstIndex(where: { $0.id == tabObject.id }) {
                        space.tabs.remove(at: legacyIndex)
                    }
                    
                    // Find replacement tab
                    let replacement = findReplacementTab(removedGroupIndex: groupIndex, groups: groups)
                    
                    if let replacementTab = replacement {
                        Task { await selectOrLoadTab(tabObject: replacementTab) }
                    } else {
                        currentTabs = [[]]
                    }
                    
                    return replacement
                }
            }
        }
        return nil
    }
    
    private func findReplacementTab(removedGroupIndex: Int, groups: [TabGroup]) -> StoredTab? {
        // Try to find a tab in the next group, then previous group
        let nextIndex = removedGroupIndex
        let prevIndex = removedGroupIndex - 1
        
        if groups.indices.contains(nextIndex), 
           let firstRow = groups[nextIndex].tabRows.first,
           let firstTab = firstRow.tabs.first {
            return firstTab
        }
        
        if groups.indices.contains(prevIndex),
           let firstRow = groups[prevIndex].tabRows.first,
           let firstTab = firstRow.tabs.first {
            return firstTab
        }
        
        return nil
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
        guard let space = selectedSpace else { return }
        
        let oldType = storedTab.tabType
        storedTab.tabType = newType
        
        // Update in-memory tabs
        for rowIdx in currentTabs.indices {
            for colIdx in currentTabs[rowIdx].indices where currentTabs[rowIdx][colIdx].storedTab.id == storedTab.id {
                currentTabs[rowIdx][colIdx].tabType = newType
                currentTabs[rowIdx][colIdx].storedTab.tabType = newType
            }
        }
        
        // Move tab between groups if needed
        moveTabBetweenGroups(storedTab: storedTab, from: oldType, to: newType, space: space, modelContext: modelContext)
        
        try? modelContext.save()
    }
    
    private func moveTabBetweenGroups(storedTab: StoredTab, from oldType: TabType, to newType: TabType, space: SpaceData, modelContext: ModelContext) {
        // Remove from old group
        let oldGroups = getTabGroups(for: oldType, in: space)
        removeTabFromGroups(storedTab: storedTab, groups: oldGroups)
        
        // Add to new group
        let newGroups = getTabGroups(for: newType, in: space)
        addTabToGroups(storedTab: storedTab, groups: newGroups, tabType: newType, space: space, modelContext: modelContext)
    }
    
    private func getTabGroups(for type: TabType, in space: SpaceData) -> [TabGroup] {
        switch type {
        case .primary:
            return space.primaryTabGroups
        case .pinned:
            return space.pinnedTabGroups
        case .favorites:
            return space.favoriteTabGroups
        }
    }
    
    private func removeTabFromGroups(storedTab: StoredTab, groups: [TabGroup]) {
        for group in groups {
            for row in group.tabRows {
                if let index = row.tabs.firstIndex(where: { $0.id == storedTab.id }) {
                    row.tabs.remove(at: index)
                    return
                }
            }
        }
    }
    
    private func addTabToGroups(storedTab: StoredTab, groups: [TabGroup], tabType: TabType, space: SpaceData, modelContext: ModelContext) {
        if let firstGroup = groups.first {
            // Add to existing group
            firstGroup.addTab(storedTab)
        } else {
            // Create new group
            let newGroup = TabGroup(
                timestamp: Date.now,
                tabType: tabType,
                orderIndex: 0,
                parentSpace: space
            )
            newGroup.addTab(storedTab)
            modelContext.insert(newGroup)
            
            // Add to appropriate group array
            switch tabType {
            case .primary:
                space.primaryTabGroups.append(newGroup)
            case .pinned:
                space.pinnedTabGroups.append(newGroup)
            case .favorites:
                space.favoriteTabGroups.append(newGroup)
            }
        }
    }
}

