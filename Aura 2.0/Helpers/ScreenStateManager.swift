//
// Aura 2.0
// isFullScreen.swift
//
// Created on 13/9/25
//
// Copyright ©2025 DoorHinge Apps.
//
    

import SwiftUI

@Observable class ScreenStateManager {
    var isFullScreen: Bool = false
    
    var screenWidth = UIScreen.main.bounds.width
    var screenHeight = UIScreen.main.bounds.height
    
    var appWindowWidth: CGFloat?
    var appWindowHeight: CGFloat?
    
    func defineBoundsAndUpdate(appWindowWidth: CGFloat, appWindowHeight: CGFloat) {
        self.appWindowWidth = appWindowWidth
        self.appWindowHeight = appWindowHeight
        
        updateScreenState()
    }
    
    func updateScreenState() {
        if let appWindowWidth = appWindowWidth, let appWindowHeight = appWindowHeight {
            withAnimation {
                if appWindowWidth == screenWidth && appWindowHeight == screenHeight {
                    isFullScreen = true
                }
                else {
                    isFullScreen = false
                }
            }
        }
    }
}
