//
// Aura 2.0
// SpaceData.swift
//
// Created on 6/11/25
//
// Copyright ©2025 DoorHinge Apps.
//


import Foundation
import SwiftData

@Model
final class SpaceData {
    // A unique identifier assigned to the space when it is created.
    // This is shared by all tabs in the space and is what sorts them.
    var spaceIdentifier: String
    
    // The display name of the space
    var spaceName: String
    
    var isIncognito: Bool
    
    // The color gradient of the background as hex codes
    var spaceBackgroundColors: [String]
    
    var primaryTabs: [StoredTab] = []
    var pinnedTabs: [StoredTab] = []
    var favoriteTabs: [StoredTab] = []
    
    init(
        spaceIdentifier: String,
        spaceName: String,
        isIncognito: Bool,
        spaceBackgroundColors: [String],
        primaryTabs: [StoredTab] = [],
        pinnedTabs: [StoredTab] = [],
        favoriteTabs: [StoredTab] = []
    ) {
        self.spaceIdentifier = spaceIdentifier
        self.spaceName = spaceName
        self.isIncognito = isIncognito
        self.spaceBackgroundColors = spaceBackgroundColors
        self.primaryTabs = primaryTabs
        self.pinnedTabs = pinnedTabs
        self.favoriteTabs = favoriteTabs
    }
}
