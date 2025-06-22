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
    var tabs: [[StoredTab]] = [[]]

    /// Flattened collection of every stored tab. This mirrors the previous
    /// single dimensional storage while supporting nested layouts.
    var allTabs: [StoredTab] { tabs.flatMap { $0 } }
    
    // --- Derived sections (not stored) ---
    var primaryTabs: [StoredTab] {
        allTabs.filter { $0.tabType == .primary }
            .sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var pinnedTabs: [StoredTab] {
        allTabs.filter { $0.tabType == .pinned }
            .sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var favoriteTabs: [StoredTab] {
        allTabs.filter { $0.tabType == .favorites }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    /// Remove the provided tab from the nested `tabs` collection.
    func removeTab(_ tab: StoredTab) {
        for rowIndex in tabs.indices {
            if let idx = tabs[rowIndex].firstIndex(where: { $0.id == tab.id }) {
                tabs[rowIndex].remove(at: idx)
                if tabs[rowIndex].isEmpty && tabs.count > 1 {
                    tabs.remove(at: rowIndex)
                }
                return
            }
        }
    }

    /// Append a tab to the specified row, creating rows as needed.
    func addTab(_ tab: StoredTab, toRow row: Int = 0) {
        if tabs.isEmpty { tabs.append([]) }
        if row >= tabs.count {
            tabs.append(contentsOf: Array(repeating: [], count: row - tabs.count + 1))
        }
        tabs[row].append(tab)
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
