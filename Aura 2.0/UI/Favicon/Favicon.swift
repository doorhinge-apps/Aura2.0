//
// Aura 2.0
// Favicon.swift
//
// Created on 6/11/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import SDWebImageSwiftUI

struct Favicon: View {
    @State var url: String
    @EnvironmentObject var settingsManager: SettingsManager
    var body: some View {
        WebImage(url: URL(string: "https://www.google.com/s2/favicons?domain=\(url)&sz=\(128)".replacingOccurrences(of: "https://www.google.com/s2/favicons?domain=Optional(", with: "https://www.google.com/s2/favicons?domain=").replacingOccurrences(of: ")&sz=", with: "&sz=").replacingOccurrences(of: "\"", with: ""))) { image in
            image
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .cornerRadius(settingsManager.faviconShape == "square" ? 0: settingsManager.faviconShape == "squircle" ? 5: 100)
                .padding(.leading, 5)
            
        } placeholder: {
            LoadingAnimations(size: 25, borderWidth: 5.0)
                .padding(.leading, 5)
        }
        .onSuccess { image, data, cacheType in
            
        }
        .transition(.fade(duration: 0.5))
        .scaledToFit()
    }
}
