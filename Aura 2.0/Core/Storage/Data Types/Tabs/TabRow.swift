//
// Aura 2.0
// TabRow.swift
//
// Created on 7/29/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import SwiftData

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
