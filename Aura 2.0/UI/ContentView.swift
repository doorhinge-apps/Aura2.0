//
// Aura 2.0
// ContentView.swift
//
// Created on 6/10/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import SwiftData
import WebKit
import Combine

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var spaces: [SpaceData]
    
    @StateObject var storageManager = StorageManager()
    @StateObject var uiViewModel = UIViewModel()
    @StateObject var tabsManager = TabsManager()
    @StateObject var settingsManager = SettingsManager()
    
    @State var selectedSpace: SpaceData
    
    var cancellables = Set<AnyCancellable>()
    
    @State private var htmlOutput: String = ""
    
    @State var htmlStringInspector = ""
    @State var urlStringInspector = ""
    
    @Namespace var namespace
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ZStack {
                    if storageManager.selectedSpace?.adaptiveTheme ?? false && storageManager.currentTabs.first?.first?.page.themeColor != nil {
                        storageManager.currentTabs.first?.first?.page.themeColor
                    }
                    else {
                        LinearGradient(
                            colors: backgroundGradientColors,
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        ).ignoresSafeArea()
                    }
                    
                    HStack(spacing: 0) {
                        if settingsManager.tabsPosition == "left" && uiViewModel.showSidebar {
                            Sidebar()
                                .matchedGeometryEffect(id: "Sidebar", in: namespace)
                                .padding([.vertical, .leading], 20)
                        }
                        
                        ZStack {
                            WebsitePanel()
                                .scrollEdgeEffectStyle(.none, for: .all)
                                .overlay {
                                    if !uiViewModel.sidebarOffset && !uiViewModel.showSidebar {
                                        Color.white.opacity(0.001)
                                            .onTapGesture {
                                                withAnimation(.easeInOut) {
                                                    uiViewModel.sidebarOffset = true
                                                }
                                            }
                                    }
                                }
                            
                            if !uiViewModel.showSidebar {
                                HStack {
                                    if settingsManager.tabsPosition == "right" {
                                        Spacer()
//                                            .frame(width: uiViewModel.sidebarOffset ? geo.size.width + uiViewModel.sidebarWidth * 2: .infinity)
                                    }
                                    Sidebar()
                                        .padding(.leading, 20)
                                        .background {
                                            GeometryReader { sideGeo in
                                                LinearGradient(
                                                    colors: backgroundGradientColors,
                                                    startPoint: .bottomLeading,
                                                    endPoint: .topTrailing
                                                )
                                                .ignoresSafeArea()
                                                .frame(width: sideGeo.size.width)
                                            }
                                        }
                                        .padding(.top, 40)
                                        .padding(.bottom, 30)
                                        .padding(.horizontal, 20)
                                        .offset(x: uiViewModel.sidebarOffset
                                                ? (uiViewModel.sidebarWidth + 80) *
                                                  (settingsManager.tabsPosition == "right" ? 1 : -1)
                                                : 0)
                                        .allowsHitTesting(!uiViewModel.sidebarOffset)     // no ghost hits
                                        .onHover { over in
                                            if !over {                                    // pointer left sidebar
                                                withAnimation(.easeInOut) {
                                                    uiViewModel.sidebarOffset = true      // hide
                                                }
                                            }
                                        }
                                    
                                    if settingsManager.tabsPosition == "left" {
                                        Spacer()
//                                            .frame(width: uiViewModel.sidebarOffset ? geo.size.width + uiViewModel.sidebarWidth * 2: .infinity)
                                    }
                                }
                                
                                HStack {
                                    if settingsManager.tabsPosition == "right" {
                                        Spacer()
                                    }
                                    Color.white.opacity(0.001)
                                        .frame(width: 20)
                                        .onTapGesture {
                                            withAnimation(.easeInOut) {
                                                uiViewModel.sidebarOffset = false
                                            }
                                        }
                                        .onHover { hovering in
                                            withAnimation(.easeInOut) {
                                                uiViewModel.sidebarOffset = false
                                            }
                                        }
                                    
                                    if settingsManager.tabsPosition == "left" {
                                        Spacer()
                                    }
                                }
                            }
                        }
                        
                        if settingsManager.tabsPosition == "right" && uiViewModel.showSidebar {
                            Sidebar()
                                .matchedGeometryEffect(id: "Sidebar", in: namespace)
                                .padding([.vertical, .trailing], 20)
                        }
                        
                        if uiViewModel.showInspector && !storageManager.currentTabs.isEmpty {
                            if !storageManager.currentTabs[0].isEmpty {
                                Inspector(htmlString: $htmlStringInspector)
                                    .onAppear() {
                                        Task {
                                            print("hello 3")
                                            do {
                                                htmlStringInspector = try await fetchHTML(from: storageManager.currentTabs[0][0].page.url?.absoluteString ?? "")
                                                print(htmlStringInspector)
                                            } catch {
                                                print("Error: \(error)")
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }.overlay {
                    if uiViewModel.showCommandBar {
                        Color.white.opacity(0.001)
                            .onTapGesture {
                                uiViewModel.showCommandBar = false
                                uiViewModel.commandBarText = ""
                                uiViewModel.searchSuggestions = []
                            }
                    }
                }
                
                if uiViewModel.showCommandBar {
                    CommandBar(geo: geo)
                }
            }
            .onAppear {
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
                    selectedSpace = spaces.first!
                }
            }
            .onChange(of: selectedSpace) { _, _ in
                try? modelContext.save()
            }
            .task {
                storageManager.initializeSelectedSpace(from: spaces, modelContext: modelContext)
            }
        }
//        .ignoresSafeArea()
        .environmentObject(storageManager)
        .environmentObject(uiViewModel)
        .environmentObject(settingsManager)
        .environmentObject(tabsManager)
        
    }
    
    var backgroundGradientColors: [Color] {
        let hexes = storageManager.selectedSpace?.spaceBackgroundColors ?? ["8041E6", "A0F2FC"]
        return hexes.map { Color(hex: $0) }
    }
}

