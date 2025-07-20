//
// Aura 2.0
// MobileWebView.swift
//
// Created on 7/16/25
//
// Copyright ©2025 DoorHinge Apps.
//

import SwiftUI
import WebKit

struct MobileWebView: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.25))
                
                VStack {
                    if !storageManager.currentTabs.isEmpty && !storageManager.currentTabs[0].isEmpty {
                        let currentTab = storageManager.currentTabs[0][0]
                        
                        WebViewFallback(currentTab.page)
                            .frame(width: geo.size.width - 20, height: geo.size.height - 20)
                            .cornerRadius(10)
                            .clipped()
                            .onTapGesture {
                                // Handle tap to focus if needed
                                storageManager.updateFocusedWebsite([0, 0])
                            }
                    } else {
                        VStack {
                            Spacer()
                            Text("No tab loaded")
                                .foregroundColor(.white)
                                .font(.title2)
                            Spacer()
                        }
                    }
                }
                .padding(10)
            }
        }
        .onAppear {
            print("DEBUG: MobileWebView appeared")
            print("DEBUG: currentTabs count: \(storageManager.currentTabs.count)")
            if !storageManager.currentTabs.isEmpty {
                print("DEBUG: currentTabs[0] count: \(storageManager.currentTabs[0].count)")
            }
        }
    }
}

#Preview {
    MobileWebView()
}