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
import WebKit

struct StoredTab: @MainActor Codable, Hashable {
//    var uuid: UUID = UUID()
    var id: String
    var timestamp: Date
    var url: String
    var tabType: TabType
    var folderName: String?
}

func createStoredTabID(url: String) -> String {
    let date = Date.now
    var id = url + date.hashValue.description
    return id
}
