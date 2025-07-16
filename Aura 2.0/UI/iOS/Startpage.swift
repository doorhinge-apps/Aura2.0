//
// Aura 2.0
// Startpage.swift
//
// Created on 7/16/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import SwiftData

struct Startpage: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var spaces: [SpaceData]
    
    @State var selectedSpace: SpaceData
    
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    @Namespace var namespace
    
    @State var currentTab: BrowserTab?
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: backgroundGradientColors, startPoint: .top, endPoint: .bottom)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
    
    var backgroundGradientColors: [Color] {
        let hexes = storageManager.selectedSpace?.spaceBackgroundColors ?? ["8041E6", "A0F2FC"]
        return hexes.map { Color(hex: $0) }
    }
}
