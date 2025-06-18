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
    @Published var currentTabs: [[BrowserTab]]
    init() {
        self.currentTabs = []

        self.currentTabs.append([
            makeTab(url: "https://apple.com"),
            makeTab(url: "https://figma.com")
        ])

        self.currentTabs.append([
            makeTab(url: "https://arc.net"),
            makeTab(url: "https://google.com"),
            makeTab(url: "https://thebrowser.company")
        ])

        self.currentTabs.append([
            makeTab(url: "https://doorhingeapps.com")
        ])
    }
    
    private func makeTab(url: String) -> BrowserTab {
            let page = WebPage()
            var request = URLRequest(url: URL(string: url)!)
            request.attribution = .user
            page.load(request)

        let stored = StoredTab(id: createStoredTabID(url: url),
                               timestamp: .now,
                               url: url,
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
//    @Published var currentTabs: [[BrowserTab]] = []
    
    
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
    
    func newTab(unformattedString: String, space: SpaceData, modelContext: ModelContext) {
        let formattedURL = formatURL(from: unformattedString)
        let page = WebPage()
        var request = URLRequest(url: URL(string: formattedURL)!)
        request.attribution = .user
        page.load(request)
        
        let storedTabObject = StoredTab(
            id: createStoredTabID(url: formattedURL),
            timestamp: Date.now,
            url: formattedURL,
            tabType: .primary,
            parentSpace: space
        )

        // Add to the space's storedTabs and persist
        modelContext.insert(storedTabObject)
        space.primaryTabs.append(storedTabObject)
        try? modelContext.save()
        
        let createdTab = BrowserTab(lastActiveTime: Date.now, tabType: .primary, page: page, storedTab: storedTabObject)

        currentTabs = [[createdTab]]
        
        appendAndRemove(addingTab: createdTab)
    }
    
    func closeTab(tabObject: StoredTab, tabType: TabType) {
        switch tabType {
        case .primary:
            if let index = selectedSpace?.primaryTabs.firstIndex(where: { $0.id == tabObject.id }) {
                selectedSpace?.primaryTabs.remove(at: index)
            }
        case .pinned:
            if let index = selectedSpace?.pinnedTabs.firstIndex(where: { $0.id == tabObject.id }) {
                selectedSpace?.pinnedTabs.remove(at: index)
            }
        case .favorites:
            if let index = selectedSpace?.favoriteTabs.firstIndex(where: { $0.id == tabObject.id }) {
                selectedSpace?.favoriteTabs.remove(at: index)
            }
        }
        if currentTabs.joined().contains(where: { $0.storedTab.id == tabObject.id }) {
            currentTabs = [[]]
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
}

