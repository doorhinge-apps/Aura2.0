//
// Aura 2.0
// HoverDisabledVision.swift
//
// Created on 6/18/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI


// This view disables the iPad and Mac custom hover interaction for visionOS users
struct HoverButtonDisabledVision: View {
    @Binding var hoverInteraction: Bool
    var body: some View {
#if !os(visionOS)
        Color(.white)
            .opacity(hoverInteraction ? 0.5: 0.0)
#endif
    }
}
