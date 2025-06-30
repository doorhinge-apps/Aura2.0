//
// Aura 2.0
// GlassEffect.swift
//
// Created on 6/24/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI

struct GlassEffectIfAvailable: ViewModifier {
    @EnvironmentObject var settingsManager: SettingsManager

    var enabled: Bool?
    func body(content: Content) -> some View {
        Group {
            if #available(iOS 26, *), enabled != false {
                content.glassEffect()
            } else {
                content
            }
        }
    }
}



struct TintedGlassEffect1IfAvailable: ViewModifier {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular.tint(
                    Color(hex: storageManager.selectedSpace?.spaceBackgroundColors.first ?? "8041E6")
                        .opacity(uiViewModel.commandBarText.isEmpty ? 0.0 : 0.5)
                ).interactive(), isEnabled: settingsManager.liquidGlassCommandBar)
        }
        else {
            content
        }
    }
}


struct TintedGlassEffect2IfAvailable: ViewModifier {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel

    var suggestion: String
    var currentSuggestionIndex: Int

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            let shouldTint = currentSuggestionIndex == uiViewModel.searchSuggestions.firstIndex(of: suggestion)
            let tintOpacity = shouldTint ? 0.5 : 0.0
            return content
                .glassEffect(
                    .regular.tint(
                        Color(hex: storageManager.selectedSpace?.spaceBackgroundColors.first ?? "8041E6")
                            .opacity(tintOpacity)
                    ),
                    isEnabled: settingsManager.liquidGlassCommandBar
                )
        } else {
            return content
        }
    }
}
