// StoredTab.swift
import Foundation
import SwiftData

@Model
final class StoredTab {
    var id: String = UUID().uuidString
    var timestamp: Date = Date()
    var url: String = ""
    var orderIndex: Int = 0
    var tabType: TabType = TabType.primary // You'll need to add a default case to your TabType enum
    var folderName: String?
    var isTemporary: Bool = false
    
    @Relationship var parentSpace: SpaceData?   // inverse handled above
    @Relationship var parentRow: TabRow?
    
    init() {}
    
    init(
        id: String,
        timestamp: Date = .now,
        url: String,
        orderIndex: Int,
        tabType: TabType,
        folderName: String? = nil,
        isTemporary: Bool = false,
        parentSpace: SpaceData? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.url = url
        self.orderIndex = orderIndex
        self.tabType = tabType
        self.folderName = folderName
        self.isTemporary = isTemporary
        self.parentSpace = parentSpace
    }
}

/// Generates a unique identifier for a stored tab using the url and date.
func createStoredTabID(url: String) -> String {
    let date = Date.now
    let id = url + date.hashValue.description
    return id
}
