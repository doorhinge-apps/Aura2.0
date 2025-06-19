import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct TabDragItem: Transferable, Codable, Equatable {
    var id: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .tabDragItem)
    }
}

extension UTType {
    static let tabDragItem = UTType(exportedAs: "com.doorhingeapps.tabdragitem")
}
