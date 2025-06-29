//
// Aura 2.0
// ScrollEdge.swift
//
// Created on 6/24/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI

struct ScrollEdgeIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .scrollEdgeEffectStyle(.none, for: .all)
        }
        else {
            content
        }
    }
}

struct ScrollEdgeDisabledIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .scrollEdgeEffectDisabled(true)
        }
        else {
            content
        }
    }
}
