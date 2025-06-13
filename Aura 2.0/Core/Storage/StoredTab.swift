//
// Aura 2.0
// Item.swift
//
// Created on 6/10/25
//
// Copyright ©2025 DoorHinge Apps.
//


import Foundation
import SwiftData

@Model
final class StoredTab {
    var uuid: UUID = UUID()
    var timestamp: Date
    var url: String
    var tabType: TabType

    @Relationship var parentSpace: SpaceData?

    init(
        uuid: UUID = UUID(),
        timestamp: Date,
        url: String,
        tabType: TabType,
        parentSpace: SpaceData? = nil
    ) {
        self.uuid = uuid
        self.timestamp = timestamp
        self.url = url
        self.tabType = tabType
        self.parentSpace = parentSpace
    }
}
