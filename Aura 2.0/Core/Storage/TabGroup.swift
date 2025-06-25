// TabGroup.swift
import Foundation
import SwiftData

// Represents one tab with its nested [[StoredTab]] structure
@Model
final class TabGroup {
    var id: String = UUID().uuidString
    var timestamp: Date = Date()
    var tabType: TabType = TabType.primary // You'll need to add a default case to your TabType enum
    var orderIndex: Int = 0
    
    @Relationship(deleteRule: .cascade, inverse: \TabRow.parentGroup)
    var tabRows: [TabRow]? = []
    
    // Separate inverse relationships for each type of parent space
    @Relationship var primarySpace: SpaceData?
    @Relationship var pinnedSpace: SpaceData?
    @Relationship var favoriteSpace: SpaceData?
    
    init() {}
    
    init(
        id: String = UUID().uuidString,
        timestamp: Date = .now,
        tabType: TabType,
        orderIndex: Int,
        parentSpace: SpaceData? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.tabType = tabType
        self.orderIndex = orderIndex
        
        // Set the appropriate parent space based on tabType
        switch tabType {
        case .primary:
            self.primarySpace = parentSpace
        case .pinned:
            self.pinnedSpace = parentSpace
        case .favorites:
            self.favoriteSpace = parentSpace
        }
    }
    
    // Convert to nested array structure [[StoredTab]]
    var nestedTabs: [[StoredTab]] {
        return (tabRows ?? []).sorted { $0.rowIndex < $1.rowIndex }.map { row in
            (row.tabs ?? []).sorted { $0.orderIndex < $1.orderIndex }
        }
    }
    
    // Convert to nested array structure excluding temporary tabs
    var nestedTabsExcludingTemporary: [[StoredTab]] {
        return (tabRows ?? []).sorted { $0.rowIndex < $1.rowIndex }.compactMap { row in
            let nonTempTabs = (row.tabs ?? []).filter { !$0.isTemporary }.sorted { $0.orderIndex < $1.orderIndex }
            return nonTempTabs.isEmpty ? nil : nonTempTabs
        }
    }
    
    // Check if this TabGroup has any non-temporary tabs
    var hasNonTemporaryTabs: Bool {
        return (tabRows ?? []).contains { row in
            (row.tabs ?? []).contains { !$0.isTemporary }
        }
    }
    
    // Helper method to add a new row of tabs
    func addTabRow(tabs: [StoredTab]) {
        let newRow = TabRow(
            rowIndex: (tabRows ?? []).count,
            parentGroup: self
        )
        for (index, tab) in tabs.enumerated() {
            tab.orderIndex = index
            tab.parentRow = newRow
            newRow.tabs?.append(tab)
        }
        if tabRows == nil {
            tabRows = []
        }
        tabRows?.append(newRow)
    }
    
    // Helper method to add a single tab to the first row
    func addTab(_ tab: StoredTab) {
        if tabRows?.isEmpty ?? true {
            addTabRow(tabs: [tab])
        } else {
            tab.orderIndex = tabRows?[0].tabs?.count ?? 0
            tab.parentRow = tabRows?[0]
            tabRows?[0].tabs?.append(tab)
        }
    }
    
    // Create from nested array structure
    static func from(nestedTabs: [[StoredTab]], tabType: TabType, orderIndex: Int, parentSpace: SpaceData?) -> TabGroup {
        let group = TabGroup(tabType: tabType, orderIndex: orderIndex, parentSpace: parentSpace)
        
        for (rowIndex, tabRow) in nestedTabs.enumerated() {
            let row = TabRow(rowIndex: rowIndex, parentGroup: group)
            for (colIndex, tab) in tabRow.enumerated() {
                tab.orderIndex = colIndex
                tab.parentSpace = parentSpace
                tab.parentRow = row
                if row.tabs == nil {
                    row.tabs = []
                }
                row.tabs?.append(tab)
            }
            if group.tabRows == nil {
                group.tabRows = []
            }
            group.tabRows?.append(row)
        }
        
        return group
    }
}

// Represents one row of tabs in the nested structure
@Model
final class TabRow {
    var id: String = UUID().uuidString
    var rowIndex: Int = 0
    
    @Relationship(deleteRule: .cascade, inverse: \StoredTab.parentRow)
    var tabs: [StoredTab]? = []
    
    @Relationship var parentGroup: TabGroup?
    
    init() {}
    
    init(
        id: String = UUID().uuidString,
        rowIndex: Int,
        parentGroup: TabGroup? = nil
    ) {
        self.id = id
        self.rowIndex = rowIndex
        self.parentGroup = parentGroup
    }
}
