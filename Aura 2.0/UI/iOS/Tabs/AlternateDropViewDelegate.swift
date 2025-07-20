//
// Aura 2.0
// AlternateDropViewDelegate.swift
//
// Created on 7/20/25
//
// Copyright ©2025 DoorHinge Apps.
//

import SwiftUI

struct AlternateDropViewDelegate: DropDelegate {
    let destinationItem: BrowserTab
    @Binding var allTabs: [BrowserTab]
    @Binding var draggedItem: BrowserTab?
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedTab = draggedItem else { return false }
        
        // Find the current position and destination position
        guard let fromIndex = allTabs.firstIndex(where: { $0.id == draggedTab.id }),
              let toIndex = allTabs.firstIndex(where: { $0.id == destinationItem.id }) else {
            return false
        }
        
        // Reorder the tabs
        withAnimation {
            let movedTab = allTabs.remove(at: fromIndex)
            allTabs.insert(movedTab, at: toIndex)
        }
        
        draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedTab = draggedItem else { return }
        
        if draggedTab.id != destinationItem.id {
            let fromIndex = allTabs.firstIndex(where: { $0.id == draggedTab.id }) ?? 0
            let toIndex = allTabs.firstIndex(where: { $0.id == destinationItem.id }) ?? 0
            
            withAnimation(.default) {
                allTabs.move(fromOffsets: IndexSet([fromIndex]), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            }
        }
    }
}