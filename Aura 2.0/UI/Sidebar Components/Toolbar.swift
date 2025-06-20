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
                ZStack {
                    Color.white.opacity(uiViewModel.hoveringID == "sidebarShowHide" ? 0.25: 0.0)
                    
                    Image(systemName: "sidebar.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff"))
                        .opacity(uiViewModel.hoveringID == "sidebarShowHide" ? 1.0: 0.5)
                    
                }.frame(width: 40, height: 40).cornerRadius(7)
                    .onHover { hover in
                        withAnimation {
                            if uiViewModel.hoveringID == "sidebarShowHide" {
                                uiViewModel.hoveringID = ""
                            }
                            else {
                                uiViewModel.hoveringID = "sidebarShowHide"
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    Toolbar()
}
