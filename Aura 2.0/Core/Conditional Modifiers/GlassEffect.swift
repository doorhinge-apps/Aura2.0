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
                content
#if !os(visionOS)
                    .glassEffect()
                #endif
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
            if settingsManager.liquidGlassCommandBar {
                content
#if !os(visionOS)
                    .glassEffect(.regular.tint(
                        Color(hex: storageManager.selectedSpace?.spaceBackgroundColors.first ?? "8041E6")
                            .opacity(uiViewModel.commandBarText.isEmpty ? 0.0 : 0.5)
                    ).interactive())
#endif
            }
            else {
                content
            }
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
        content
            .modifier(ConditionalGlassEffect(
                shouldApplyGlass: settingsManager.liquidGlassCommandBar,
                suggestion: suggestion,
                currentSuggestionIndex: currentSuggestionIndex,
                storageManager: storageManager,
                uiViewModel: uiViewModel
            ))
    }
}

struct ConditionalGlassEffect: ViewModifier {
    let shouldApplyGlass: Bool
    let suggestion: String
    let currentSuggestionIndex: Int
    let storageManager: StorageManager
    let uiViewModel: UIViewModel
    
    func body(content: Content) -> some View {
        Group {
            if shouldApplyGlass {
                if #available(iOS 26, *) {
                    let shouldTint = currentSuggestionIndex == uiViewModel.searchSuggestions.firstIndex(of: suggestion)
                    let tintOpacity = shouldTint ? 0.5 : 0.0
                    content
#if !os(visionOS)
                        .glassEffect(
                            .regular.tint(
                                Color(hex: storageManager.selectedSpace?.spaceBackgroundColors.first ?? "8041E6")
                                    .opacity(tintOpacity)
                            )
                        )
#endif
                } else {
                    content
                }
            } else {
                content
            }
        }
    }
}
