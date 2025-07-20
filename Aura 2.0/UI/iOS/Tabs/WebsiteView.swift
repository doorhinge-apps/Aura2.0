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
            
            VStack(spacing: 0) {
                // Web content - reuse the existing page from the tab
                WebViewFallback(tab.page)
                    .ignoresSafeArea(.all, edges: .horizontal)
                    .matchedGeometryEffect(id: tab.id, in: namespace)
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.container)
    }
}