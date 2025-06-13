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
    
    @State var scrollPosition = ScrollPosition()
    
    @State var findNavigatorIsPresent: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Button {
                    findNavigatorIsPresent.toggle()
                } label: {
                    Color.white.opacity(0.001)
                }.keyboardShortcut("f", modifiers: .command)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.25))
                
                VStack {
                    ForEach(storageManager.currentTabs, id:\.self) { tabRow in
                        HStack {
                            ForEach(tabRow, id:\.id) { website in
                                WebView(website.page)
                                    .scrollBounceBehavior(.basedOnSize, axes: .horizontal) // Fixes issue with horizontal scrolling without overflow
                                    .webViewScrollPosition($scrollPosition)
                                    .findNavigator(isPresented: $findNavigatorIsPresent)
                                    .cornerRadius(10)
                                    
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    WebsitePanel()
}
