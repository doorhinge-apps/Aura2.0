// SpaceData.swift
import Foundation
import SwiftData

@Model
final class SpaceData {
    var spaceIdentifier: String = UUID().uuidString
    var spaceName: String = "Untitled Space"
    var spaceIcon: String = "circle.fill"
    var isIncognito: Bool = false
    var spaceBackgroundColors: [String] = []
    var textColor: String = "#ffffff"
    var adaptiveTheme: Bool = false
    var spaceOrder: Int?
    
    // Legacy tabs relationship - keeping for migration
    @Relationship(deleteRule: .cascade, inverse: \StoredTab.parentSpace)
    var tabs: [StoredTab]? = []
    
    // New nested structure using TabGroup
    @Relationship(deleteRule: .cascade, inverse: \TabGroup.primarySpace)
    var primaryTabGroups: [TabGroup]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \TabGroup.pinnedSpace)
    var pinnedTabGroups: [TabGroup]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \TabGroup.favoriteSpace)
    var favoriteTabGroups: [TabGroup]? = []
    
    // --- Computed properties for nested arrays ---
    // Returns [[[StoredTab]]] - array of nested tab structures
    var primaryTabsNested: [[[StoredTab]]] {
        return (primaryTabGroups ?? []).sorted { $0.orderIndex < $1.orderIndex }
            .map { $0.nestedTabs }
    }
    
    var pinnedTabsNested: [[[StoredTab]]] {
        return (pinnedTabGroups ?? []).sorted { $0.orderIndex < $1.orderIndex }
            .map { $0.nestedTabs }
    }
    
    var favoriteTabsNested: [[[StoredTab]]] {
        return (favoriteTabGroups ?? []).sorted { $0.orderIndex < $1.orderIndex }
            .map { $0.nestedTabs }
    }
    
    // --- Backward compatibility flat arrays ---
    var primaryTabs: [StoredTab] {
        return (primaryTabGroups ?? []).flatMap { $0.tabRows?.flatMap { $0.tabs ?? [] } ?? [] }
            .sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var pinnedTabs: [StoredTab] {
        return (pinnedTabGroups ?? []).flatMap { $0.tabRows?.flatMap { $0.tabs ?? [] } ?? [] }
            .sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var favoriteTabs: [StoredTab] {
        return (favoriteTabGroups ?? []).flatMap { $0.tabRows?.flatMap { $0.tabs ?? [] } ?? [] }
            .sorted { $0.orderIndex < $1.orderIndex }
    }
    
    init() {}
    
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
