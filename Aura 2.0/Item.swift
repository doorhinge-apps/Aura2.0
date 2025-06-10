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
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
