//
// Aura 2.0
// WebsitePanel.swift
//
// Created on 6/11/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import WebKit

struct WebsitePanel: View {
    @EnvironmentObject var storageManager: StorageManager
    var body: some View {
        VStack {
            ForEach(storageManager.currentTabs, id:\.self) { tabRow in
                HStack {
                    ForEach(tabRow, id:\.id) { website in
                        WebView(website.page)
                    }
                }
            }
        }
    }
}

#Preview {
    WebsitePanel()
}
