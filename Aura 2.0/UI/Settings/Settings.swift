//
// Aura 2.0
// Settings.swift
//
// Created on 6/14/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import WebKit

struct Settings: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            ).ignoresSafeArea()
            
            NavigationStack {
                NavigationLink {
                    GeneralSettings()
                } label: {
                    Text("General")
                }

            }
        }
    }
    
    var backgroundGradientColors: [Color] {
        let hexes = storageManager.selectedSpace?.spaceBackgroundColors ?? ["8041E6", "A0F2FC"]
        return hexes.map { Color(hex: $0) }
    }
}
