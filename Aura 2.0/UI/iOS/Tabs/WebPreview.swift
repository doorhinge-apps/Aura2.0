//
// Aura 2.0
// WebPreview.swift
//
// Created on 7/20/25
//
// Copyright ©2025 DoorHinge Apps.
//

import SwiftUI

struct WebPreview: View {
    let namespace: Namespace.ID
    let url: String
    let geo: GeometryProxy
    let tab: BrowserTab
    @Binding var browseForMeTabs: [String]
    
    var body: some View {
        VStack(spacing: 8) {
            // Web snapshot with 4:3 aspect ratio
            UrlSnapshotView(urlString: tab.storedTab.url)
                .scaledToFill()
                .frame(width: geo.size.width/2 - 20, height: (geo.size.width/2 - 20) * (4/3), alignment: .top)
                .cornerRadius(15)
                .clipped()
            
            // Title underneath
            Text(tab.storedTab.url)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
        }
    }
}
