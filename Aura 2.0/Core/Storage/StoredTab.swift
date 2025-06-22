// StoredTab.swift
import Foundation
import SwiftData

@Model
final class StoredTab: Codable {
    var id: String
    var timestamp: Date
    var url: String
    var orderIndex: Int
    var tabType: TabType
    var folderName: String?
    
    @Relationship var parentSpace: SpaceData?   // inverse handled above
    
    init(
        id: String,
        timestamp: Date = .now,
        url: String,
        orderIndex: Int,
        tabType: TabType,
        folderName: String? = nil,
        parentSpace: SpaceData? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.url = url
        self.orderIndex = orderIndex
        self.tabType = tabType
        self.folderName = folderName
        self.parentSpace = parentSpace
    }
}

/// Generates a unique identifier for a stored tab using the url and date.
func createStoredTabID(url: String) -> String {
    let date = Date.now
    let id = url + date.hashValue.description
    return id
}
