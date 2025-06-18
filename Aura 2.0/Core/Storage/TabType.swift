//
// Aura 2.0
// TabType.swift
//
// Created on 6/10/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI

/// Type of a stored tab. Uses a `String` raw value so it can be
/// persisted by SwiftData.
enum TabType: String, Codable {
    case primary
    case pinned
    case favorites
}

