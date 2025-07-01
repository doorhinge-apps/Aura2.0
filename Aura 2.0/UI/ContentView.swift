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
    
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
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
                    if storageManager.selectedSpace?.adaptiveTheme ?? false,
                       let color = storageManager.currentTabs.first?.first?.page.themeColor,
                       color.isDark() {
                        color.ignoresSafeArea()
                    } else {
                        LinearGradient(
                            colors: backgroundGradientColors,
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                        .ignoresSafeArea()
                        .animation(.default)
                    }
                    
                    HStack(spacing: 0) {
                        if settingsManager.tabsPosition == "left" && uiViewModel.showSidebar {
                            Sidebar()
                                .matchedGeometryEffect(id: "Sidebar", in: namespace)
                                .padding([.vertical, .leading], 20)
                        }
                        
                        ZStack {
                            WebsitePanel()
//                                .scrollEdgeEffectStyle(.none, for: .all)
                                .modifier(ScrollEdgeIfAvailable())
                                .padding(.top, settingsManager.showBorder ? 15 : 0)
                                .padding(.bottom, settingsManager.showBorder ? 15 : 0)
                                .padding(.leading, (settingsManager.tabsPosition == "right" || !uiViewModel.showSidebar) ? (settingsManager.showBorder ? 15 : 0) : 0)
                                .padding(.trailing, (settingsManager.tabsPosition == "left" || !uiViewModel.showSidebar) ? (settingsManager.showBorder ? 15 : 0) : 0)
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
                                    }
                                    Sidebar()
                                        .padding(.leading, 20)
                                        .background {
                                            GeometryReader { sideGeo in
                                                ZStack {
                                                    LinearGradient(
                                                        colors: firstHalfGradientColors,
                                                        startPoint: .bottomLeading,
                                                        endPoint: .topTrailing
                                                    )
                                                    .ignoresSafeArea()
                                                    .frame(width: sideGeo.size.width)
                                                }.cornerRadius(20)
                                            }
                                        }
                                        .padding(.top, 40)
                                        .padding(.bottom, 30)
                                        .padding(.horizontal, 20)
                                        .offset(x: uiViewModel.sidebarOffset
                                                ? (uiViewModel.sidebarWidth + 80) *
                                                  (settingsManager.tabsPosition == "right" ? 1 : -1)
                                                : 0)
                                        .allowsHitTesting(!uiViewModel.sidebarOffset)
                                        .onHover { over in
                                            if !over {
                                                withAnimation(.easeInOut) {
                                                    uiViewModel.sidebarOffset = true
                                                }
                                            }
                                        }
                                    
                                    if settingsManager.tabsPosition == "left" {
                                        Spacer()
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
    
    var firstHalfGradientColors: [Color] {
        let hexes = storageManager.selectedSpace?.spaceBackgroundColors ?? ["8041E6", "A0F2FC"]
        guard !hexes.isEmpty else { return [] }

        let count = hexes.count
        let half  = (count + 1) / 2  // rounds up for odd counts

        if count.isMultiple(of: 2) {
            // mix the two middle colors correctly using `by`
            let mixed = Color(hex: hexes[half - 1])
                .mix(with: Color(hex: hexes[half]), by: 0.5)
            
            return hexes.prefix(half - 1).map { Color(hex: $0) } + [mixed]
        } else {
            return hexes.prefix(half).map { Color(hex: $0) }
        }
    }
}

