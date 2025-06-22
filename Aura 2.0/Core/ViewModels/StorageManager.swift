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
    
    // Focus state for website panel - [rowIndex, columnIndex]
    @Published var focusedWebsite: [Int] = []
    
    
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
        guard let space = selectedSpace else { return }
        
        if let index = splitViewTabs.firstIndex(where: { $0.mainTab == tabObject }) {
            splitViewTabs[index].subTabLayout = currentTabs
        } else {
            // Find the TabGroup that contains this tab
            if let tabGroup = findTabGroup(containingTabId: tabObject.id, space: space) {
                // Restore the entire nested structure from the TabGroup
                currentTabs = await loadTabGroupAsCurrentTabs(tabGroup: tabGroup)
            } else {
                // Fallback: create a single tab if no TabGroup found
                await loadSingleTab(tabObject: tabObject)
            }
        }
        
        if loadedTabs.count >= Int(settingManager.preloadingWebsites) {
            loadedTabs.removeFirst()
        }
        
        // Set focus to the selected tab
        setFocusToTab(tabObject: tabObject)
    }
    
    /// Load a TabGroup and convert it to [[BrowserTab]] structure
    private func loadTabGroupAsCurrentTabs(tabGroup: TabGroup) async -> [[BrowserTab]] {
        var result: [[BrowserTab]] = []
        
        for row in tabGroup.tabRows.sorted(by: { $0.rowIndex < $1.rowIndex }) {
            var browserRow: [BrowserTab] = []
            
            for storedTab in row.tabs.sorted(by: { $0.orderIndex < $1.orderIndex }) {
                // Check if we already have this tab loaded
                if let existingTab = loadedTabs.first(where: { $0.storedTab.id == storedTab.id }) {
                    browserRow.append(existingTab)
                } else {
                    // Create new BrowserTab
                    let browserTab = await createBrowserTab(from: storedTab)
                    browserRow.append(browserTab)
                    loadedTabs.append(browserTab)
                }
            }
            
            result.append(browserRow)
        }
        
        return result
    }
    
    /// Create a BrowserTab from a StoredTab
    private func createBrowserTab(from storedTab: StoredTab) async -> BrowserTab {
        let newWebPage = WebPage()
        var request = URLRequest(url: URL(string: storedTab.url)!)
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
        
        return BrowserTab(
            lastActiveTime: Date.now,
            tabType: storedTab.tabType,
            page: newWebPage,
            storedTab: storedTab
        )
    }
    
    /// Fallback method to load a single tab
    private func loadSingleTab(tabObject: StoredTab) async {
        if let existingTab = loadedTabs.first(where: { $0.storedTab.id == tabObject.id }) {
            currentTabs = [[existingTab]]
        } else {
            let browserTab = await createBrowserTab(from: tabObject)
            currentTabs = [[browserTab]]
            loadedTabs.append(browserTab)
        }
    }
    
    /// Set focus to the specified tab within currentTabs
    private func setFocusToTab(tabObject: StoredTab) {
        for (rowIndex, row) in currentTabs.enumerated() {
            for (colIndex, browserTab) in row.enumerated() {
                if browserTab.storedTab.id == tabObject.id {
                    focusedWebsite = [rowIndex, colIndex]
                    return
                }
            }
        }
        // Default to first tab if not found
        if !currentTabs.isEmpty && !currentTabs[0].isEmpty {
            focusedWebsite = [0, 0]
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
            // Migrate legacy tabs to TabGroups if needed
            migrateLegacyTabsToGroups(modelContext: modelContext)
        }
    }
    
    /// Migrate any legacy individual StoredTabs to TabGroup structure
    private func migrateLegacyTabsToGroups(modelContext: ModelContext) {
        guard let space = selectedSpace else { return }
        
        // Check if we have legacy tabs that aren't in TabGroups
        let legacyTabs = space.tabs.filter { tab in
            findTabGroup(containingTabId: tab.id, space: space) == nil
        }
        
        if !legacyTabs.isEmpty {
            print("Migrating \(legacyTabs.count) legacy tabs to TabGroup structure")
            
            for tab in legacyTabs {
                // Create a TabGroup for each individual tab
                let tabGroup = TabGroup(
                    timestamp: tab.timestamp,
                    tabType: tab.tabType,
                    orderIndex: getTabGroups(for: tab.tabType, in: space).count,
                    parentSpace: space
                )
                
                tabGroup.addTab(tab)
                modelContext.insert(tabGroup)
                addTabGroupToSpace(tabGroup: tabGroup, space: space)
            }
            
            try? modelContext.save()
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
    
    // MARK: - Split View Methods
    
    /// Update the focused website position
    func updateFocusedWebsite(_ position: [Int]) {
        focusedWebsite = position
    }
    
    /// Add a new tab to the current row (horizontal split)
    func addTabToCurrentRow(url: String, rowIndex: Int, modelContext: ModelContext) {
        guard rowIndex < currentTabs.count,
              let space = selectedSpace else { return }
        
        let page = WebPage()
        var request = URLRequest(url: URL(string: url)!)
        request.attribution = .user
        page.load(request)
        
        // Get the tab type from the current tab in this row
        let currentTabType = currentTabs[rowIndex].first?.tabType ?? .primary
        
        let storedTab = StoredTab(
            id: createStoredTabID(url: url),
            timestamp: Date.now,
            url: url,
            orderIndex: currentTabs[rowIndex].count,
            tabType: currentTabType,
            parentSpace: space
        )
        
        let browserTab = BrowserTab(
            lastActiveTime: Date.now,
            tabType: currentTabType,
            page: page,
            storedTab: storedTab
        )
        
        // Add to current tabs
        currentTabs[rowIndex].append(browserTab)
        
        // Find the TabGroup that contains the current tab and add to the correct row
        let currentTabId = currentTabs[rowIndex].first?.storedTab.id ?? ""
        if let tabGroup = findTabGroup(containingTabId: currentTabId, space: space) {
            // Add to the same row as the existing tab
            if let targetRow = tabGroup.tabRows.first(where: { row in
                row.tabs.contains { $0.id == currentTabId }
            }) {
                targetRow.tabs.append(storedTab)
            }
        }
        
        modelContext.insert(storedTab)
        space.tabs.append(storedTab)
        
        try? modelContext.save()
        
        // Set focus to the new tab
        focusedWebsite = [rowIndex, currentTabs[rowIndex].count - 1]
    }
    
    /// Add a new row to current tabs (vertical split)
    func addNewRowToCurrentTabs(url: String, modelContext: ModelContext) {
        guard let space = selectedSpace else { return }
        
        let page = WebPage()
        var request = URLRequest(url: URL(string: url)!)
        request.attribution = .user
        page.load(request)
        
        // Get tab type from current context - use the type of the currently selected tab
        let currentTabType = getFocusedTab()?.tabType ?? .primary
        
        let storedTab = StoredTab(
            id: createStoredTabID(url: url),
            timestamp: Date.now,
            url: url,
            orderIndex: 0,
            tabType: currentTabType,
            parentSpace: space
        )
        
        let browserTab = BrowserTab(
            lastActiveTime: Date.now,
            tabType: currentTabType,
            page: page,
            storedTab: storedTab
        )
        
        // Add new row to current tabs
        currentTabs.append([browserTab])
        
        // Find the TabGroup that we're currently viewing and add a new row to it
        let currentTabId = getFocusedTab()?.storedTab.id ?? currentTabs.first?.first?.storedTab.id ?? ""
        if let tabGroup = findTabGroup(containingTabId: currentTabId, space: space) {
            // Add a new row to the existing TabGroup
            tabGroup.addTabRow(tabs: [storedTab])
        } else {
            // Create new TabGroup if none found (fallback)
            let tabGroup = TabGroup(
                timestamp: Date.now,
                tabType: currentTabType,
                orderIndex: getTabGroups(for: currentTabType, in: space).count,
                parentSpace: space
            )
            tabGroup.addTab(storedTab)
            
            modelContext.insert(tabGroup)
            addTabGroupToSpace(tabGroup: tabGroup, space: space)
        }
        
        modelContext.insert(storedTab)
        space.tabs.append(storedTab)
        
        try? modelContext.save()
        
        // Set focus to the new tab
        focusedWebsite = [currentTabs.count - 1, 0]
    }
    
    /// Get the currently focused tab if valid
    func getFocusedTab() -> BrowserTab? {
        guard focusedWebsite.count == 2,
              focusedWebsite[0] < currentTabs.count,
              focusedWebsite[1] < currentTabs[focusedWebsite[0]].count else {
            return nil
        }
        return currentTabs[focusedWebsite[0]][focusedWebsite[1]]
    }
    
    /// Find the TabGroup that contains a specific tab ID
    private func findTabGroup(containingTabId tabId: String, space: SpaceData) -> TabGroup? {
        let allGroups = space.primaryTabGroups + space.pinnedTabGroups + space.favoriteTabGroups
        
        for group in allGroups {
            for row in group.tabRows {
                if row.tabs.contains(where: { $0.id == tabId }) {
                    return group
                }
            }
        }
        return nil
    }
    
    /// Add a TabGroup to the appropriate array in SpaceData
    private func addTabGroupToSpace(tabGroup: TabGroup, space: SpaceData) {
        switch tabGroup.tabType {
        case .primary:
            space.primaryTabGroups.append(tabGroup)
        case .pinned:
            space.pinnedTabGroups.append(tabGroup)
        case .favorites:
            space.favoriteTabGroups.append(tabGroup)
        }
    }
    
    // MARK: - Tab Context Methods
    
    /// Create a new tab for a specific type (used by sidebar components)
    func newTabForType(unformattedString: String, space: SpaceData, tabType: TabType, modelContext: ModelContext) -> StoredTab {
        let formattedURL = formatURL(from: unformattedString)
        let page = WebPage()
        var request = URLRequest(url: URL(string: formattedURL)!)
        request.attribution = .user
        page.load(request)
        
        let newOrder = getTabGroups(for: tabType, in: space).count
        let storedTabObject = StoredTab(
            id: createStoredTabID(url: formattedURL),
            timestamp: Date.now,
            url: formattedURL,
            orderIndex: 0,
            tabType: tabType,
            parentSpace: space
        )
        
        // Create a new TabGroup for this single tab
        let tabGroup = TabGroup(
            timestamp: Date.now,
            tabType: tabType,
            orderIndex: newOrder,
            parentSpace: space
        )
        
        tabGroup.addTab(storedTabObject)
        
        modelContext.insert(storedTabObject)
        modelContext.insert(tabGroup)
        addTabGroupToSpace(tabGroup: tabGroup, space: space)
        space.tabs.append(storedTabObject)
        
        try? modelContext.save()
        
        let createdTab = BrowserTab(lastActiveTime: Date.now, tabType: tabType, page: page, storedTab: storedTabObject)
        currentTabs = [[createdTab]]
        appendAndRemove(addingTab: createdTab)
        
        return storedTabObject
    }
    
    /// Close an entire TabGroup
    func closeTabGroup(tabGroup: TabGroup, modelContext: ModelContext) -> StoredTab? {
        guard let space = selectedSpace else { return nil }
        
        // Remove the TabGroup from the appropriate array
        switch tabGroup.tabType {
        case .primary:
            if let index = space.primaryTabGroups.firstIndex(where: { $0.id == tabGroup.id }) {
                space.primaryTabGroups.remove(at: index)
            }
        case .pinned:
            if let index = space.pinnedTabGroups.firstIndex(where: { $0.id == tabGroup.id }) {
                space.pinnedTabGroups.remove(at: index)
            }
        case .favorites:
            if let index = space.favoriteTabGroups.firstIndex(where: { $0.id == tabGroup.id }) {
                space.favoriteTabGroups.remove(at: index)
            }
        }
        
        // Remove all tabs from the legacy tabs array and delete them
        for row in tabGroup.tabRows {
            for tab in row.tabs {
                if let legacyIndex = space.tabs.firstIndex(where: { $0.id == tab.id }) {
                    space.tabs.remove(at: legacyIndex)
                }
                modelContext.delete(tab)
            }
        }
        
        // Delete the TabGroup itself
        modelContext.delete(tabGroup)
        
        // Find a replacement TabGroup to switch to
        let replacementGroup = findReplacementTabGroup(removedGroup: tabGroup, space: space)
        
        if let replacement = replacementGroup?.tabRows.first?.tabs.first {
            Task { await selectOrLoadTab(tabObject: replacement) }
            return replacement
        } else {
            currentTabs = [[]]
            return nil
        }
    }
    
    /// Find a replacement TabGroup after one is closed
    private func findReplacementTabGroup(removedGroup: TabGroup, space: SpaceData) -> TabGroup? {
        let groups = getTabGroups(for: removedGroup.tabType, in: space)
        
        // Try to find the next group with higher order index
        let nextGroup = groups.first { $0.orderIndex > removedGroup.orderIndex }
        if let next = nextGroup {
            return next
        }
        
        // Fall back to the previous group
        let prevGroup = groups.filter { $0.orderIndex < removedGroup.orderIndex }.max { $0.orderIndex < $1.orderIndex }
        if let prev = prevGroup {
            return prev
        }
        
        // Try other tab types if no replacement found in same type
        let allGroups = space.primaryTabGroups + space.pinnedTabGroups + space.favoriteTabGroups
        return allGroups.first
    }
}

