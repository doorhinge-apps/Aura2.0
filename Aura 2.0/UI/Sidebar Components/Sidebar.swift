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
import UniformTypeIdentifiers

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
    
    @State private var draggingTabID: String?
    
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
                            if !hoverSearch && settingsManager.useUnifiedToolbar {
                                Spacer()
                            }
                            
                            HStack {
                                if storageManager.currentTabs.first?.first?.page != nil {
                                    Menu {
                                        if storageManager.currentTabs.first?.first?.page.hasOnlySecureContent ?? false {
                                            Label("Secure", systemImage: "lock.fill")
                                                .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff").opacity(0.5))
                                        }
                                        else {
                                            Label("Not Secure", systemImage: "lock.open.fill")
                                                .foregroundStyle(Color.red)
                                        }
                                    } label: {
                                        Image(systemName: storageManager.currentTabs.first?.first?.page.hasOnlySecureContent ?? false ? "lock.fill": "lock.open.fill")
                                            .font(.system(.body, design: .rounded, weight: .semibold))
                                            .foregroundStyle(storageManager.currentTabs.first?.first?.page.hasOnlySecureContent ?? false ? Color.white: Color.red)
                                    }

                                }
                                else {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(.body, design: .rounded, weight: .semibold))
                                        .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff").opacity(0.5))
                                }
                                
                                Text(hoverSearch || !settingsManager.useUnifiedToolbar ? unformatURL(url: getFocusedOrFirstTabURL()): "")
                                    .lineLimit(1)
                                    .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff").opacity(0.5))
                            }
//                            Label(hoverSearch || !settingsManager.useUnifiedToolbar ? unformatURL(url: storageManager.currentTabs.first?.first?.storedTab.url ?? "Search or Enter URL"): "", systemImage: "magnifyingglass")
//                                .lineLimit(1)
//                                .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff").opacity(0.5))
                            
                            Spacer()
                            
                            if (hoverSearch) && storageManager.currentTabs.first?.first?.page != nil {
                                Button {
                                    UIPasteboard.general.string = storageManager.currentTabs[0][0].storedTab.url
                                } label: {
                                    ZStack {
                                        Color.white.opacity(uiViewModel.hoveringID == "searchbarCopy" ? 0.25: 0.0)
                                        
                                        Image(systemName: "link")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff"))
                                            .opacity(uiViewModel.hoveringID == "searchbarCopy" ? 1.0: 0.5)
                                        
                                    }.frame(width: 40, height: 40).cornerRadius(7)
                                        .onHover { hover in
                                            withAnimation {
                                                if uiViewModel.hoveringID == "searchbarCopy" {
                                                    uiViewModel.hoveringID = ""
                                                }
                                                else {
                                                    uiViewModel.hoveringID = "searchbarCopy"
                                                }
                                            }
                                        }
                                }
                                
                                
                                Button {
                                    let activityController = UIActivityViewController(activityItems: [storageManager.currentTabs.first?.first?.page.url ?? URL(string: "")!, storageManager.currentTabs.first?.first?.page ?? WebPage()], applicationActivities: nil)
                                    
                                    if let popoverController = activityController.popoverPresentationController {
                                        popoverController.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
                                        
                                        popoverController.permittedArrowDirections = [.up]
                                        popoverController.permittedArrowDirections = []
                                    }
                                    
                                    UIApplication.shared.windows.first?.rootViewController!.present(activityController, animated: true, completion: nil)
                                } label: {
                                    ZStack {
                                        Color.white.opacity(uiViewModel.hoveringID == "searchbarShare" ? 0.25: 0.0)
                                        
                                        Image(systemName: "square.and.arrow.up")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff"))
                                            .opacity(uiViewModel.hoveringID == "searchbarShare" ? 1.0: 0.5)
                                        
                                    }.frame(width: 40, height: 40).cornerRadius(7)
                                        .onHover { hover in
                                            withAnimation {
                                                if uiViewModel.hoveringID == "searchbarShare" {
                                                    uiViewModel.hoveringID = ""
                                                }
                                                else {
                                                    uiViewModel.hoveringID = "searchbarShare"
                                                }
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, 15)
                        .frame(width: hoverSearch || !settingsManager.useUnifiedToolbar ? .infinity: 50, height: 50)
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
                                FavoriteTabsGridView(space: space, draggingTabID: $draggingTabID)
                                PinnedTabsView(space: space, draggingTabID: $draggingTabID)
                                
                                SpaceToolsBar()

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
                                                .foregroundStyle(Color(hex: space.textColor))
                                                .font(.system(.headline, design: .rounded, weight: .bold))
                                                .padding(.leading, 10)

                                            Spacer()
                                        }
                                    }.foregroundStyle(Color(hex: space.textColor))
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
                                }

                                PrimaryTabsView(space: space, draggingTabID: $draggingTabID)
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
    
    /// Get the URL of the focused tab, or fallback to first tab
    private func getFocusedOrFirstTabURL() -> String {
        // Try to get focused tab URL
        if let focusedTab = storageManager.getFocusedTab() {
            return focusedTab.storedTab.url
        }
        
        // Fallback to first tab
        return storageManager.currentTabs.first?.first?.storedTab.url ?? "Search or Enter URL"
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

struct TabDropDelegate: DropDelegate {
    let tab: StoredTab
    let space: SpaceData
    let tabType: TabType
    @Binding var draggingTabID: String?
    var modelContext: ModelContext

    // Fire on hover, just for the live animation.
    func dropEntered(info: DropInfo) {
        guard
            let draggingID = draggingTabID,
            draggingID != tab.id
        else { return }

        // Work on a snapshot that reflects the on-screen order
        var ordered: [StoredTab]
        switch tabType {
        case .primary:
            ordered = space.primaryTabs.sorted { $0.orderIndex > $1.orderIndex }
        case .pinned:
            ordered = space.pinnedTabs.sorted { $0.orderIndex < $1.orderIndex }
        case .favorites:
            ordered = space.favoriteTabs.sorted { $0.orderIndex < $1.orderIndex }
        }

        guard
            let from = ordered.firstIndex(where: { $0.id == draggingID }),
            let to   = ordered.firstIndex(where: { $0.id == tab.id })
        else { return }

        withAnimation {
            let moved = ordered.remove(at: from)
            ordered.insert(moved, at: to)

            // The order you show is driven solely by this field
            for (i, t) in ordered.enumerated() { t.orderIndex = i }
        }
        // no save here – keeps the gesture smooth
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    // Commit once, when the user lets go
    func performDrop(info: DropInfo) -> Bool {
        draggingTabID = nil
        do { try modelContext.save() }            // persist the new order
        catch { assertionFailure("SwiftData save failed: \(error)") }
        return true
    }
}

struct TabGroupDropDelegate: DropDelegate {
    let tabGroup: TabGroup
    let space: SpaceData
    @Binding var draggingTabID: String?
    var modelContext: ModelContext

    func dropEntered(info: DropInfo) {
        guard
            let draggingID = draggingTabID,
            draggingID != (tabGroup.tabRows.first?.tabs.first?.id ?? tabGroup.id)
        else { return }

        // Work on a snapshot that reflects the on-screen order for TabGroups
        var orderedGroups: [TabGroup]
        switch tabGroup.tabType {
        case .primary:
            orderedGroups = space.primaryTabGroups.sorted { $0.orderIndex < $1.orderIndex }
        case .pinned:
            orderedGroups = space.pinnedTabGroups.sorted { $0.orderIndex < $1.orderIndex }
        case .favorites:
            orderedGroups = space.favoriteTabGroups.sorted { $0.orderIndex < $1.orderIndex }
        }

        guard
            let from = orderedGroups.firstIndex(where: { group in
                group.tabRows.contains { row in
                    row.tabs.contains { $0.id == draggingID }
                }
            }),
            let to = orderedGroups.firstIndex(where: { $0.id == tabGroup.id })
        else { return }

        withAnimation {
            let moved = orderedGroups.remove(at: from)
            orderedGroups.insert(moved, at: to)

            // Update order indices
            for (i, group) in orderedGroups.enumerated() { 
                group.orderIndex = i 
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        draggingTabID = nil
        do { try modelContext.save() }
        catch { assertionFailure("SwiftData save failed: \(error)") }
        return true
    }
}



