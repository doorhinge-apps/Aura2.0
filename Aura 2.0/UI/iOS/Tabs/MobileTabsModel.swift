//
// Aura 2.0
// MobileTabsModel.swift
//
// Created by Reyna Myers on 26/10/24
//
// Copyright ©2024 DoorHinge Apps.
//

import SwiftUI
import Combine

/// Mobile-specific UI state for iOS tabs interface
/// Tab data and management is handled by StorageManager and UIViewModel
class MobileTabsModel: ObservableObject {
    
    // MARK: - Mobile-specific UI State
    
    /// Browse for Me functionality - tracks which tabs have this enabled
    @Published var browseForMeTabs: [String] = []
    
    // MARK: - Gesture & Animation State
    
    /// Drag offsets for tab cards during gestures
    @Published var offsets: [UUID: CGSize] = [:]
    
    /// Rotation tilts for tab cards during drag
    @Published var tilts: [UUID: Double] = [:]
    
    /// Z-index values for tab layering during interactions
    @Published var zIndexes: [UUID: Double] = [:]
    
    /// Currently dragged tab for reordering
    @Published var draggedTab: BrowserTab?
    
    // MARK: - Fullscreen Web View State
    
    /// Whether a tab is displayed in fullscreen mode
    @Published var fullScreenWebView = false
    
    /// Drag offset for fullscreen web view
    @Published var tabOffset = CGSize.zero
    
    /// Scale factor for fullscreen web view
    @Published var tabScale: CGFloat = 1.0
    
    /// Whether a gesture is currently active
    @Published var gestureStarted = false
    
    /// Exponential damping factor for gestures
    @Published var exponentialThing = 1.0
    
    // MARK: - Mobile UI Controls
    
    /// Whether new tab creation was triggered from within a tab
    @Published var newTabFromTab = false
    
    /// Counter for disabling scroll during tab close gestures
    @Published var closeTabScrollDisabledCounter = 0
    
    // MARK: - Grid Display
    
    /// Number of columns in the tab grid
    @AppStorage("gridColumnCount") var gridColumnCount = 2.0
    
    // MARK: - Helper Methods
    
    /// Reset all gesture-related state
    func resetGestureState() {
        offsets.removeAll()
        tilts.removeAll()
        zIndexes.removeAll()
        draggedTab = nil
        gestureStarted = false
        exponentialThing = 1.0
    }
    
    /// Reset fullscreen state
    func resetFullscreenState() {
        fullScreenWebView = false
        tabOffset = .zero
        tabScale = 1.0
        newTabFromTab = false
    }
}
