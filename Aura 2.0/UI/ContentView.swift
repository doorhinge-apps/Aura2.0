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

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var spaces: [SpaceData]
    
    @StateObject var storageManager = StorageManager()
    @StateObject var uiViewModel = UIViewModel()
    @StateObject var tabsManager = TabsManager()
    @StateObject var settingsManager = SettingsManager()
    
    @State var selectedSpace: SpaceData
    @State var selectedTab: WebPage = WebPage()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ZStack {
                    LinearGradient(
                        colors: backgroundGradientColors,
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    ).ignoresSafeArea()
                    
                    HStack {
                        Sidebar()
                        
                        Button {
                            uiViewModel.showCommandBar.toggle()
                        } label: {
                            Image(systemName: "plus")
                        }
                        
                        WebsitePanel()
                            .padding(settingsManager.showBorder ? 20: 0)
                            .scrollEdgeEffectStyle(.none, for: .all)
                    }
                }.onTapGesture {
                    if uiViewModel.showCommandBar {
                        uiViewModel.showCommandBar = false
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
                        spaceBackgroundColors: ["8041E6", "A0F2FC"]
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
        }.environmentObject(storageManager)
            .environmentObject(uiViewModel)
    }
    
    var backgroundGradientColors: [Color] {
        let hexes = storageManager.selectedSpace?.spaceBackgroundColors ?? ["8041E6", "A0F2FC"]
        return hexes.map { Color(hex: $0) }
    }
}

