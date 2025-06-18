import Foundation
import SwiftData

/// A persisted representation of a browser tab.
@Model
final class StoredTab {
    var id: String
    var timestamp: Date
    var url: String
    var tabType: TabType
    var folderName: String?

    /// The space that owns this tab.
    @Relationship var parentSpace: SpaceData?

    init(id: String,
         timestamp: Date,
         url: String,
         tabType: TabType,
         folderName: String? = nil,
         parentSpace: SpaceData? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.url = url
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
