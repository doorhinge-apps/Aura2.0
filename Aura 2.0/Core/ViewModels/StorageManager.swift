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
    @StateObject var settingManager = SettingsManager()
    
    @Published var selectedSpace: SpaceData?
    // Tabs currently loaded in the background
    @Published var loadedTabs: [BrowserTab] = []
    
    // Tabs currently open
    // This update will allow for split view. This will work with nested arrays.
    // Each array is a row. The number of items in each array is the number of collumns.
    // Aura will load all of these at the same time
    @Published var currentTabs: [[BrowserTab]] = []
    
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
            timestamp: Date.now,
            url: formattedURL,
            tabType: .primary
        )
        
        // Add to the space's storedTabs and persist
        space.primaryTabs.append(storedTabObject)
        try? modelContext.save()
        
        let createdTab = BrowserTab(lastActiveTime: Date.now, tabType: .primary, page: page, storedTab: storedTabObject)

        currentTabs = [[createdTab]]
        
        appendAndRemove(addingTab: createdTab)
    }
    
    func closeTab(tabObject: StoredTab, tabType: TabType) {
        switch tabType {
        case .primary:
            if let index = selectedSpace?.primaryTabs.firstIndex(where: { $0.uuid == tabObject.uuid }) {
                selectedSpace?.primaryTabs.remove(at: index)
            }
        case .pinned:
            if let index = selectedSpace?.pinnedTabs.firstIndex(where: { $0.uuid == tabObject.uuid }) {
                selectedSpace?.pinnedTabs.remove(at: index)
            }
        case .favorites:
            if let index = selectedSpace?.favoriteTabs.firstIndex(where: { $0.uuid == tabObject.uuid }) {
                selectedSpace?.favoriteTabs.remove(at: index)
            }
        }
        if currentTabs.joined().contains(where: { $0.storedTab.uuid == tabObject.uuid }) {
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
                spaceBackgroundColors: ["8041E6", "A0F2FC"]
            )
            modelContext.insert(newSpace)
            try? modelContext.save()
            selectedSpace = newSpace
        } else {
            selectedSpace = spaces.first
        }
    }
}

