// SpaceData.swift
import Foundation
import SwiftData

@Model
final class SpaceData {
    var spaceIdentifier: String
    var spaceName: String
    var spaceIcon: String = "circle.fill"
    var isIncognito: Bool
    var spaceBackgroundColors: [String]
    var textColor: String
    var adaptiveTheme: Bool = false
    
    // Persist *all* tabs in one place
    @Relationship(deleteRule: .cascade, inverse: \StoredTab.parentSpace)
    var tabs: [StoredTab] = []
    
    // --- Derived sections (not stored) ---
    var primaryTabs: [StoredTab] {
        tabs.filter { $0.tabType == .primary }
            .sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var pinnedTabs: [StoredTab] {
        tabs.filter { $0.tabType == .pinned }
            .sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var favoriteTabs: [StoredTab] {
        tabs.filter { $0.tabType == .favorites }
            .sorted { $0.orderIndex < $1.orderIndex }
    }
    
    init(
        spaceIdentifier: String,
        spaceName: String,
        isIncognito: Bool,
        spaceBackgroundColors: [String],
        textColor: String
    ) {
        self.spaceIdentifier = spaceIdentifier
        self.spaceName = spaceName
        self.isIncognito = isIncognito
        self.spaceBackgroundColors = spaceBackgroundColors
        self.textColor = textColor
    }
}
