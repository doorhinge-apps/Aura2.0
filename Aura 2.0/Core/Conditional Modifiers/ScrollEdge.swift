//
// Aura 2.0
// ScrollEdge.swift
//
// Created on 6/24/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import WebKit

struct ScrollEdgeIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
#if !os(visionOS)
                .scrollEdgeEffectStyle(.none, for: .all)
            #endif
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
            #if !os(visionOS)
                .scrollEdgeEffectDisabled(true)
            #endif
        }
        else {
            content
        }
    }
}

//struct WebViewModifiersIfAvailable: ViewModifier {
//    @Binding var scrollPosition: ScrollPosition
//    func body(content: Content) -> some View {
//        if #available(iOS 26, *) {
//            content
//                .webViewScrollPosition($scrollPosition)
//        }
//        else {
//            content
//        }
//    }
//}
