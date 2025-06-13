//
// Aura 2.0
// Sidebar.swift
//
// Created on 6/11/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import SwiftData

struct Sidebar: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @StateObject var tabsManager = TabsManager()
    
    @Environment(\.modelContext) private var modelContext
    @Query private var spaces: [SpaceData]
    
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                TextField("Search or enter URL", text: $uiViewModel.commandBarText)
                TabView(selection: $storageManager.selectedSpace) {
                    ForEach(spaces, id:\.id) { space in
                        ScrollView {
                            VStack {
                                if let selectedSpace = storageManager.selectedSpace {
                                    ForEach(selectedSpace.primaryTabs, id:\.self) { tab in
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color.white.opacity(0.001))
                                            
                                            if !storageManager.currentTabs.isEmpty {
                                                if !storageManager.currentTabs[0].isEmpty {
                                                    RoundedRectangle(cornerRadius: 15)
                                                        .fill(Color.white.opacity(storageManager.currentTabs[0][0].storedTab == tab ? 0.5: uiViewModel.currentHoverTab == tab ? 0.25: 0.001))
                                                        .animation(.easeInOut, value: storageManager.currentTabs[0][0].storedTab == tab)
                                                }
                                            }
                                            
                                            HStack {
                                                Favicon(url: tab.url)
                                                Text(tabsManager.linksWithTitles[tab.url] ?? tab.url)
//                                                Text(tab.timestamp.description)
                                                    .lineLimit(1)
                                                    .onAppear {
                                                        Task {
                                                            await tabsManager.fetchTitlesIfNeeded(for: [tab.url])
                                                        }
                                                    }
                                                Spacer()
                                                Button {
                                                    storageManager.closeTab(tabObject: tab, tabType: .primary)
                                                } label: {
                                                    Image(systemName: "xmark")
                                                }
                                            }
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 5)
                                        }
                                        .onTapGesture {
                                            Task {
                                                await storageManager.selectOrLoadTab(tabObject: tab)
                                                
                                                if let index = selectedSpace.primaryTabs.firstIndex(where: { $0.uuid == tab.uuid }) {
                                                    var updatedTabs = selectedSpace.primaryTabs
                                                    updatedTabs[index].timestamp = Date.now
                                                    selectedSpace.primaryTabs = updatedTabs

                                                    try? modelContext.save()
                                                }
                                            }
                                        }

                                    }
                                }
                            }
                        }
                    }
                }
                .tabViewStyle(.page)
            }
            .frame(width: uiViewModel.sidebarWidth + dragOffset)
            .clipped()

            // Resizable drag handle
            Rectangle()
                .fill(Color.gray.opacity(0.001)) // Invisible but still tappable
                .frame(width: 15)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let proposedWidth = uiViewModel.sidebarWidth + value.translation.width
                            if proposedWidth > 150 && proposedWidth < 400 {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            let finalWidth = uiViewModel.sidebarWidth + value.translation.width
                            uiViewModel.sidebarWidth = min(max(finalWidth, 150), 400)
                            dragOffset = 0
                        }
                )
//                .background(Color.secondary.opacity(0.05))
                .contentShape(Rectangle())
        }
    }
}

