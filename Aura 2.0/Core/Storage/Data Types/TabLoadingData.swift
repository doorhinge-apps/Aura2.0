//
// Aura 2.0
// TabLoadingData.swift
//
// Created on 6/10/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI

struct TabLoadingData {
    var type: TabType
    var isSplitView: Bool
    var splitLocation: TabCoordinatePair
}

struct TabCoordinatePair {
    var x: Int
    var y: Int
}
