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
//                    Spacer()
//                        .frame(height: 50)
                    ForEach(storageManager.currentTabs, id:\.self) { tabRow in
                        HStack {
                            ForEach(tabRow, id:\.id) { website in
                                GeometryReader { geo in
                                    ZStack {
                                        WebView(website.page)
                                            .scrollEdgeEffectDisabled(true)
                                            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                                            .webViewScrollPosition($scrollPosition)
                                            .findNavigator(isPresented: $findNavigatorIsPresent)
                                            .padding(.vertical, 10)
                                            .frame(height: geo.size.height + 20)
                                    }
                                    .frame(height: geo.size.height)
                                    .cornerRadius(10)
                                    .clipped()
                                }
                            }
                        }
                    }
                }
            }
        }.scrollEdgeEffectDisabled(true)
    }
}

#Preview {
    WebsitePanel()
}
