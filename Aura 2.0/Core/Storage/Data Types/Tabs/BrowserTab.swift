//
// Aura 2.0
// BrowserTab.swift
//
// Created on 6/10/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import WebKit

/// Parsed from a StoredTab type and stores an open WKWebView and its data.
struct BrowserTab: Hashable, Identifiable {
    let id: UUID = UUID()
    var lastActiveTime: Date
    var tabType: TabType
    var page: WebPageFallback
    var storedTab: StoredTab

    static func == (lhs: BrowserTab, rhs: BrowserTab) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
