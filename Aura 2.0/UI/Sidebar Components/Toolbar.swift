//
// Aura 2.0
// Toolbar.swift
//
// Created on 6/13/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI

struct Toolbar: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        HStack {
            Button {
                withAnimation {
                    uiViewModel.showSidebar.toggle()
                }
            } label: {
                Image(systemName: "sidebar.left")
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff"))
            }
        }
    }
}

#Preview {
    Toolbar()
}
