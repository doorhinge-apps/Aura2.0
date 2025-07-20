//
// Aura 2.0
// WebsiteView.swift
//
// Created on 7/20/25
//
// Copyright ©2025 DoorHinge Apps.
//

import SwiftUI
import WebKit

struct WebsiteView: View {
    let namespace: Namespace.ID
    @Binding var url: String
    let webViewManager: WebPageFallback? // Made optional since we don't have this injected
    let parentGeo: GeometryProxy
    @Binding var webURL: String
    @Binding var fullScreenWebView: Bool
    let tab: BrowserTab
    @Binding var browseForMeTabs: [String]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Web content - reuse the existing page from the tab
                WebViewFallback(tab.page)
                    .ignoresSafeArea()
            }
        }
        .onTapGesture {
            // Close fullscreen on tap
            withAnimation {
                fullScreenWebView = false
            }
        }
    }
}