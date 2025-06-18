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
import WebKit

struct Sidebar: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    @Environment(\.modelContext) private var modelContext
    @Query private var spaces: [SpaceData]
    
    @State private var dragOffset: CGFloat = 0
    
    @State private var startWidth: CGFloat?
    
    @State var hoverSearch = false
    
    var body: some View {
        HStack(spacing: 0) {
            // MARK: - Drag to resize: Right
            if settingsManager.tabsPosition == "right" {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.001))
                        .frame(width: 15)
                        .contentShape(Rectangle())

                    if !settingsManager.hideResizingHandles {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 5, height: 30)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let proposedWidth = uiViewModel.sidebarWidth - value.translation.width
                            dragOffset = proposedWidth
                                .clamped(to: 150...400) - uiViewModel.sidebarWidth
                        }
                        .onEnded { value in
                            let finalWidth = uiViewModel.sidebarWidth - value.translation.width
                            uiViewModel.sidebarWidth = finalWidth.clamped(to: 150...400)
                            dragOffset = 0
                        }
                )
            }
            
            VStack {
                Spacer()
                    .frame(height: 50)
                
                if !settingsManager.useUnifiedToolbar {
                    Toolbar()
                }
                
                HStack {
                    Button {
                        withAnimation {
                            if hoverSearch || !settingsManager.useUnifiedToolbar {
                                uiViewModel.showCommandBar.toggle()
                            }
                            else {
                                hoverSearch = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                    withAnimation {
                                        hoverSearch = false
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            if !hoverSearch {
                                Spacer()
                            }
                            
                            Label(hoverSearch || !settingsManager.useUnifiedToolbar ? unformatURL(url: storageManager.currentTabs.first?.first?.storedTab.url ?? "Search or Enter URL"): "", systemImage: "magnifyingglass")
                                .lineLimit(1)
                                .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff").opacity(0.5))
                            
                            Spacer()
                            
                            if (hoverSearch || !settingsManager.useUnifiedToolbar) && storageManager.currentTabs.first?.first?.page != nil {
                                Button {
                                    let activityController = UIActivityViewController(activityItems: [storageManager.currentTabs.first?.first?.page.url ?? URL(string: "")!, storageManager.currentTabs.first?.first?.page ?? WebPage()], applicationActivities: nil)
                                    
                                    if let popoverController = activityController.popoverPresentationController {
                                        popoverController.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
                                        
                                        popoverController.permittedArrowDirections = [.up]
                                        popoverController.permittedArrowDirections = []
                                    }
                                    
                                    UIApplication.shared.windows.first?.rootViewController!.present(activityController, animated: true, completion: nil)
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                }
                            }
                        }
                        .padding(.horizontal, 15)
                        .frame(width: hoverSearch ? .infinity: 50, height: 50)
                            .background() {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(hoverSearch ? 0.25: 0.15))
                            }
                            .onHover { hover in
                                withAnimation {
                                    hoverSearch = hover
                                }
                            }
                    }
                    
                    if settingsManager.useUnifiedToolbar {
                        Toolbar()
                            .frame(width: hoverSearch ? 0: .infinity)
                            .clipped()
                    }
                    
                    Spacer()
                }
                
                
                
                TabView(selection: $storageManager.selectedSpace) {
                    ForEach(spaces, id:\.id) { space in
                        ScrollView {
                            VStack {
//                                if let selectedSpace = storageManager.selectedSpace {
                                    
                                    
                                    // MARK: - New Tab
                                    Button {
                                        uiViewModel.showCommandBar.toggle()
                                    } label: {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 20)
                                                .foregroundStyle(Color(.white).opacity(uiViewModel.hoveringID == "newTab" ? 0.5: 0.0))
                                                .frame(height: 50)
                                            HStack {
                                                Label("New Tab", systemImage: "plus")
                                                    .foregroundStyle(Color(hex: space.textColor ?? "ffffff"))
                                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                                    .padding(.leading, 10)
                                                
                                                Spacer()
                                            }
                                        }.foregroundStyle(Color(hex: space.textColor ?? "ffffff"))
                                            .onHover { hover in
                                                withAnimation {
                                                    let hoverID = "newTab"
                                                    if uiViewModel.hoveringID == hoverID {
                                                        uiViewModel.hoveringID = ""
                                                    }
                                                    else {
                                                        uiViewModel.hoveringID = hoverID
                                                    }
                                                }
                                            }
                                    }.keyboardShortcut("t", modifiers: .command)
                                    
                                    // MARK: - Primary Tabs
                                    ForEach(space.primaryTabs, id: \.id) { tab in
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color.white.opacity(0.001))
                                            
                                            if !storageManager.currentTabs.isEmpty {
                                                if !storageManager.currentTabs[0].isEmpty {
                                                    RoundedRectangle(cornerRadius: 15)
                                                        .fill(Color.white.opacity(uiViewModel.currentSelectedTab == tab.id ? 0.5: uiViewModel.currentHoverTab == tab ? 0.25: 0.001))
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
                                                
                                                tab.timestamp = Date.now
                                                try? modelContext.save()
                                            }
                                            uiViewModel.currentSelectedTab = tab.id
                                        }
                                        .onHover { hover in
                                            withAnimation {
                                                if uiViewModel.currentHoverTab == tab {
                                                    uiViewModel.currentHoverTab = nil
                                                }
                                                else {
                                                    uiViewModel.currentHoverTab = tab
                                                }
                                            }
                                        }
                                    }
                                //}
                            }
                        }.scrollEdgeEffectDisabled(true)
                            .tag(space)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                HStack {
                    Button {
                        uiViewModel.showSettings = true
                    } label: {
                        ZStack {
                            Color.white.opacity(uiViewModel.hoveringID == "settings" ? 0.25: 0.0)
                            
                            Image(systemName: "gearshape")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff"))
                                .opacity(uiViewModel.hoveringID == "settings" ? 1.0: 0.5)
                            
                        }.frame(width: 40, height: 40).cornerRadius(7)
                            .onHover { hover in
                                withAnimation {
                                    if uiViewModel.hoveringID == "settings" {
                                        uiViewModel.hoveringID = ""
                                    }
                                    else {
                                        uiViewModel.hoveringID = "settings"
                                    }
                                }
                            }
                    }
                    
                    // MARK: - Switch Spaces
                    ForEach(spaces, id:\.self) { space in
                        Button {
                            storageManager.selectedSpace = space
                        } label: {                            
                            ZStack {
                                Color.white.opacity(uiViewModel.hoveringID == space.spaceIdentifier ? 0.25: 0.0)
                                
                                Image(systemName: space.spaceIcon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff"))
                                    .opacity(uiViewModel.hoveringID == space.spaceIdentifier ? 1.0: 0.5)
                                
                            }.frame(width: 40, height: 40).cornerRadius(7)
                                .onHover { hover in
                                    withAnimation {
                                        if uiViewModel.hoveringID == space.spaceIdentifier {
                                            uiViewModel.hoveringID = ""
                                        }
                                        else {
                                            uiViewModel.hoveringID = space.spaceIdentifier
                                        }
                                    }
                                }
                        }
                    }
                    
                    Button {
                        let newSpace = SpaceData(
                            spaceIdentifier: UUID().uuidString,
                            spaceName: "Untitled",
                            isIncognito: false,
                            spaceBackgroundColors: ["8041E6", "A0F2FC"],
                            textColor: "#ffffff"
                        )

                        modelContext.insert(newSpace)
                    } label: {
                        ZStack {
                            Color.white.opacity(uiViewModel.hoveringID == "addNewSpace" ? 0.25: 0.0)
                            
                            Image(systemName: "plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff"))
                                .opacity(uiViewModel.hoveringID == "addNewSpace" ? 1.0: 0.5)
                            
                        }.frame(width: 40, height: 40).cornerRadius(7)
                            .onHover { hover in
                                withAnimation {
                                    if uiViewModel.hoveringID == "addNewSpace" {
                                        uiViewModel.hoveringID = ""
                                    }
                                    else {
                                        uiViewModel.hoveringID = "addNewSpace"
                                    }
                                }
                            }
                    }
                }.sheet(isPresented: $uiViewModel.showSettings) {
                    Settings()
                }
            }
            .frame(width: uiViewModel.sidebarWidth + dragOffset)
            .clipped()

            // MARK: - Drag to resize: Left
            if settingsManager.tabsPosition == "left" {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.001))
                        .frame(width: 15)
                        .contentShape(Rectangle())
                    
                    if !settingsManager.hideResizingHandles {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 5, height: 30)
                    }
                }.gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            dragOffset = (uiViewModel.sidebarWidth + value.translation.width)
                                .clamped(to: 150...400) - uiViewModel.sidebarWidth
                        }
                        .onEnded { value in
                            let finalWidth = uiViewModel.sidebarWidth + value.translation.width
                            uiViewModel.sidebarWidth = min(max(finalWidth, 150), 400)
                            dragOffset = 0
                        }
                )
            }
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
