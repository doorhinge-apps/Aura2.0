// TabGroup.swift
import Foundation
import SwiftData

// Represents one tab with its nested [[StoredTab]] structure
@Model
final class TabGroup {
    var id: String
    var timestamp: Date
    var tabType: TabType
    var orderIndex: Int
    
    @Relationship(deleteRule: .cascade)
    var tabRows: [TabRow] = []
    
    @Relationship var parentSpace: SpaceData?
    
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
        self.parentSpace = parentSpace
    }
    
    // Convert to nested array structure [[StoredTab]]
    var nestedTabs: [[StoredTab]] {
        return tabRows.sorted { $0.rowIndex < $1.rowIndex }.map { row in
            row.tabs.sorted { $0.orderIndex < $1.orderIndex }
        }
    }
    
    // Helper method to add a new row of tabs
    func addTabRow(tabs: [StoredTab]) {
        let newRow = TabRow(
            rowIndex: tabRows.count,
            parentGroup: self
        )
        for (index, tab) in tabs.enumerated() {
            tab.orderIndex = index
            newRow.tabs.append(tab)
        }
        tabRows.append(newRow)
    }
    
    // Helper method to add a single tab to the first row
    func addTab(_ tab: StoredTab) {
        if tabRows.isEmpty {
            addTabRow(tabs: [tab])
        } else {
            tab.orderIndex = tabRows[0].tabs.count
            tabRows[0].tabs.append(tab)
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
                row.tabs.append(tab)
            }
            group.tabRows.append(row)
        }
        
        return group
    }
}

// Represents one row of tabs in the nested structure
@Model
final class TabRow {
    var id: String
    var rowIndex: Int
    
    @Relationship(deleteRule: .cascade)
    var tabs: [StoredTab] = []
    
    @Relationship var parentGroup: TabGroup?
    
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