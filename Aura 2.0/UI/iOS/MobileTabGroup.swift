import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import WebKit

struct MobileTabGroup: View {
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    var tabGroup: TabGroup
    var space: SpaceData
    @Binding var draggingTabID: String?
    
    let namespace: Namespace.ID
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var degrees: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(alignment: .center) {
                    if let thing = tabGroup.tabRows?.first?.tabs?.first {
                        UrlSnapshotView(urlString: thing.url)
                            .frame(width: geo.size.width, height: geo.size.width * (4/3))
                            .cornerRadius(15)
                            .clipped()
                            .matchedGeometryEffect(id: tabGroup.tabRows?.first?.tabs?.first?.id ?? "websitePreview", in: namespace, properties: .frame, anchor: .center)
                    }
                    else {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .frame(width: geo.size.width, height: geo.size.width * (4/3))
                    }
                    
                    if settingsManager.favoritesDisplayMode.contains("icon") {
                        if isSplitView {
                            // Show multiple favicons for split view
                            HStack(spacing: 2) {
                                ForEach(Array(allTabsInGroup.prefix(4)), id: \.id) { tab in
                                    if tab.isTemporary {
                                        Image(systemName: "globe")
                                            .frame(width: 12, height: 12)
                                            .foregroundColor(.gray)
                                    } else {
                                        Favicon(url: currentTabURLs[tab.id] ?? tab.url)
                                            .frame(width: 12, height: 12)
                                    }
                                }
                                if allTabsInGroup.count > 4 {
                                    Text("+\(allTabsInGroup.count - 4)")
                                        .font(.caption2)
                                        .foregroundStyle(Color(hex: space.textColor))
                                }
                            }
                        } else {
                            // Show single favicon
                            if let firstTab = firstTab {
                                if firstTab.isTemporary {
                                    Image(systemName: "globe")
                                        .foregroundColor(.gray)
                                } else {
                                    Favicon(url: currentTabURLs[firstTab.id] ?? firstTab.url)
                                }
                            }
                        }
                    }
                    
                    if settingsManager.favoritesDisplayMode.contains("title") {
                        if isSplitView {
                            Text("Split View (\(allTabsInGroup.count))")
                                .foregroundStyle(Color(hex: space.textColor))
                                .lineLimit(1)
                                .font(.caption)
                        } else {
                            if let firstTab = firstTab {
                                if firstTab.isTemporary {
                                    Text("New Tab")
                                        .foregroundStyle(Color(hex: space.textColor))
                                        .lineLimit(1)
                                } else {
                                    Text(tabsManager.linksWithTitles[currentTabURLs[firstTab.id] ?? firstTab.url] ?? (currentTabURLs[firstTab.id] ?? firstTab.url))
                                        .foregroundStyle(Color(hex: space.textColor))
                                        .lineLimit(1)
                                        .onAppear {
                                            Task { await tabsManager.fetchTitlesIfNeeded(for: [currentTabURLs[firstTab.id] ?? firstTab.url]) }
                                        }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 5)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())

            .rotationEffect(Angle(degrees: degrees))
            .offset(x: dragOffset.width)
            .onTapGesture {
                print("Selection started")
                Task {
                    await selectTabGroup()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onChanged { gesture in
                        handleDragChange(gesture)
                    }
                    .onEnded { gesture in
                        handleDragEnd(gesture)
                    }
            )
            .contextMenu(menuItems: {
                contextMenuItems
            })
        }//.zIndex(dragOffset.width != 0 ? 100: 1)
        .shadow(color: Color(abs(dragOffset.width) > 100 ? .red: .black).opacity(abs(dragOffset.width) > 100 ? 0.75: 0.25), radius: 10, x: 0, y: 0)
        .animation(.easeInOut, value: dragOffset.width)
    }
    
    private func handleDragChange(_ gesture: DragGesture.Value) {
        if !isDragging {
            isDragging = true
        }
        
        dragOffset = gesture.translation
        
        // Calculate tilt based on drag distance
        let tilt = min(Double(abs(gesture.translation.width)) / 20, 15)
        degrees = gesture.translation.width < 0 ? -tilt : tilt
        draggingTabID = tabGroup.id.description
    }
    
    private func handleDragEnd(_ gesture: DragGesture.Value) {
        isDragging = false
        
        if abs(gesture.translation.width) > 100 {
            // Animate off screen
            withAnimation(.easeOut(duration: 0.3)) {
                dragOffset.width = gesture.translation.width < 0 ? -500 : 500
                degrees = gesture.translation.width < 0 ? -20 : 20
            }
            
            // Close the tab group after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    closeTabGroup()
                }
            }
        } else {
            // Snap back to original position
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                dragOffset = .zero
                degrees = 0
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isSplitView: Bool {
        let totalTabs = (tabGroup.tabRows ?? []).reduce(0) { $0 + ($1.tabs ?? []).count }
        return totalTabs > 1 || (tabGroup.tabRows ?? []).count > 1
    }
    
    private var firstTab: StoredTab? {
        return (tabGroup.tabRows ?? []).first?.tabs?.first { !$0.isTemporary }
    }
    
    private var allTabsInGroup: [StoredTab] {
        return (tabGroup.tabRows ?? []).flatMap {
            ($0.tabs ?? []).filter { !$0.isTemporary }.sorted { $0.orderIndex < $1.orderIndex }
        }
    }
    
    private var isCurrentlySelected: Bool {
        return allTabsInGroup.contains { tab in
            uiViewModel.currentSelectedTab == tab.id
        }
    }
    
    private var isCurrentlyHovered: Bool {
        return allTabsInGroup.contains { tab in
            uiViewModel.currentHoverTab?.id == tab.id
        }
    }
    
    private var currentTabURLs: [String: String] {
        // Use StorageManager's tracked URLs, fall back to stored URLs
        var urlDict: [String: String] = [:]
        for row in storageManager.currentTabs {
            for browserTab in row {
                if browserTab.storedTab.isTemporary {
                    urlDict[browserTab.storedTab.id] = browserTab.storedTab.url
                } else {
                    // Use tracked URL or fall back to stored URL
                    urlDict[browserTab.storedTab.id] = storageManager.currentTabURLs[browserTab.storedTab.id] ?? browserTab.storedTab.url
                }
            }
        }
        return urlDict
    }
    
    // MARK: - Actions
    
    private func selectTabGroup() async {
        if let firstTab = firstTab {
            await storageManager.selectOrLoadTab(tabObject: firstTab)
            firstTab.timestamp = Date.now
            try? modelContext.save()
            uiViewModel.currentSelectedTab = firstTab.id
        }
    }
    
    private func closeTabGroup() {
        let replacement = storageManager.closeTabGroup(tabGroup: tabGroup, modelContext: modelContext, selectNext: false)
        uiViewModel.currentSelectedTab = replacement?.id ?? ""
    }
    
    // MARK: - Context Menu
    
    private var contextMenuItems: some View {
        Group {
            if let firstTab = firstTab {
                Button {
                    UIPasteboard.general.string = firstTab.url
                } label: {
                    Label("Copy URL", systemImage: "link")
                }
            }
            
            Button {
                withAnimation {
                    closeTabGroup()
                }
            } label: {
                Label("Close Tab", systemImage: "rectangle.badge.xmark")
            }
            
            Divider()
            
            if let firstTab = firstTab {
                Button {
                    withAnimation {
                        storageManager.updateTabType(
                            for: firstTab,
                            to: firstTab.tabType == .favorites ? .primary : .favorites,
                            modelContext: modelContext
                        )
                    }
                } label: {
                    Label(firstTab.tabType == .favorites ? "Unfavorite" : "Favorite",
                          systemImage: firstTab.tabType == .favorites ? "star.fill" : "star")
                }
                
                Button {
                    withAnimation {
                        storageManager.updateTabType(
                            for: firstTab,
                            to: firstTab.tabType == .pinned ? .primary : .pinned,
                            modelContext: modelContext
                        )
                    }
                } label: {
                    Label(firstTab.tabType == .pinned ? "Unpin" : "Pin",
                          systemImage: firstTab.tabType == .pinned ? "pin.fill" : "pin")
                }
            }
        }
    }
}
