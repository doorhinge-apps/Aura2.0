//
// Aura 2.0
// iOS Button Styles.swift
//
// Created on 8/4/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.1 : 1)
            .animation(.smooth, value: configuration.isPressed)
    }
}
