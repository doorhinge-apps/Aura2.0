//
// Aura 2.0
// SettingsViewModel.swift
//
// Created on 6/11/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    @AppStorage("showBorder") var showBorder = true
    
    // left, right, top, or bottom
    @AppStorage("tabsPosition") var tabsPosition: String = "left"
    
    @AppStorage("searchEngine") var searchEngine = "https://www.google.com/search?q="
    
    // Color settings
    @AppStorage("prefferedColorScheme") var prefferedColorScheme = "automatic"
    @AppStorage("forceDarkMode") var forceDarkMode = "advanced"
    @AppStorage("forceDarkModeTime") var forceDarkModeTime = "system"
    
    @AppStorage("faviconShape") var faviconShape = "circle"
    
    @AppStorage("launchAnimation") var launchAnimation = true
    
    @AppStorage("preloadingWebsites") var preloadingWebsites = 15.0
    
    @AppStorage("hideBrowseForMe") var hideBrowseForMe = false
    
    @AppStorage("hideMagnifyingGlassSearch") var hideMagnifyingGlassSearch = true
}

