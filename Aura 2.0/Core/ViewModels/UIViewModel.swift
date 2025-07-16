//
// Aura 2.0
// UIViewModel.swift
//
// Created on 6/11/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import Combine

class UIViewModel: ObservableObject {
//    let hoveringBackgroundOpacity = 0.5
    // Shows the command bar
    @Published var showCommandBar: Bool = false
    // Determines if the command bar is editing the current url or opening a new tab
    @Published var isEditingURL: Bool = false
    @Published var commandBarText: String = ""
    
    @Published var hoveringID = ""
    
    @Published var showInspector = false
    
    @Published var currentSelectedTab: String?
    
    @Published var currentHoverTab: StoredTab?
    @Published var currentHoverTabID: UUID?
    
    @AppStorage("sidebarWidth") var sidebarWidth = CGFloat(250)
    
    @AppStorage("showSidebar") var showSidebar = true
    
    @Published var sidebarOffset = true
    
    @Published var showSettings = false
    
    @Published var showStartpage = false
    
    @Published var selectedTabs: [StoredTab]?
    
    // Search suggestions from Google
    @Published var searchSuggestions: [String] = []
    
    @Published var currentTabTypeMobile: TabType = .primary
    
    func updateSearchSuggestions() {
        Task {
            if let xml = await fetchXML(searchRequest: commandBarText) {
                searchSuggestions = formatXML(from: xml)
            }
        }
    }

    func fetchXML(searchRequest: String) async -> String? {
        guard let url = URL(string: "https://toolbarqueries.google.com/complete/search?q=\(searchRequest.replacingOccurrences(of: " ", with: "+"))&output=toolbar&hl=en") else {
            print("Invalid URL")
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Fetch error: \(error.localizedDescription)")
            return nil
        }
    }

    func formatXML(from input: String) -> [String] {
        var results = [String]()
        var currentIndex = input.startIndex

        while let startIndex = input[currentIndex...].range(of: "data=\"")?.upperBound {
            let remainingSubstring = input[startIndex...]

            if let endIndex = remainingSubstring.range(of: "\"")?.lowerBound {
                let attributeValue = input[startIndex..<endIndex]
                results.append(String(attributeValue))
                currentIndex = endIndex
            } else {
                break
            }
        }

        return results
    }
}
