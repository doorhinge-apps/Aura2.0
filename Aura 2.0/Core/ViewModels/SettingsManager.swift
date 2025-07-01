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
    @AppStorage("prefferedColorScheme") var prefferedColorScheme = "automatic" // automatic, light, dark
    @AppStorage("forceDarkMode") var forceDarkMode = "advanced" // none, basic, advanced
    @AppStorage("forceDarkModeTime") var forceDarkModeTime = "system" // system, light, dark
    
    @AppStorage("faviconShape") var faviconShape = "circle"
    
    @AppStorage("launchAnimation") var launchAnimation = true
    
    @AppStorage("preloadingWebsites") var preloadingWebsites = 15.0
    
    @AppStorage("hideBrowseForMe") var hideBrowseForMe = false
    
    @AppStorage("hideMagnifyingGlassSearch") var hideMagnifyingGlassSearch = true
    
    @AppStorage("useUnifiedToolbar") var useUnifiedToolbar = false
    
    @AppStorage("hideResizingHandles") var hideResizingHandles = false
    
    @AppStorage("commandBarOnLaunch") var commandBarOnLaunch = false
    
    @AppStorage("liquidGlassCommandBar") var liquidGlassCommandBar = true
    
    @AppStorage("adBlock") var adBlock = false
    
    @AppStorage("closePrimaryTabsAfter") var closePrimaryTabsAfter = 26297460.0 // In minutes
    
    @AppStorage("favoritesDisplayMode") var favoritesDisplayMode = "icon" // icon, title, icon+title
    
    @AppStorage("pinnedTabCornerRadius") var favoriteTabCornerRadius = 20.0
    @AppStorage("pinnedTabBorderWidth") var favoriteTabBorderWidth = 2.0
    
    @AppStorage("useDeclarativeWebView") var useDeclarativeWebView = true
}

