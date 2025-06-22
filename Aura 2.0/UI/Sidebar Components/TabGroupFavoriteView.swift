import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TabGroupFavoriteView: View {
    var tabGroup: TabGroup
    var space: SpaceData
    @Binding var draggingTabID: String?

    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: settingsManager.favoriteTabCornerRadius)
                .fill(Color.white.opacity(0.001))
            
            RoundedRectangle(cornerRadius: settingsManager.favoriteTabCornerRadius)
                .stroke(Color.white.opacity(0.5), lineWidth: settingsManager.favoriteTabBorderWidth)
                .fill(Color.white.opacity(isCurrentlySelected ? 0.5 : isCurrentlyHovered ? 0.25 : 0.001))
                .animation(.easeInOut, value: isCurrentlySelected)
                .frame(height: 75)

            VStack(alignment: .center) {
                if settingsManager.favoritesDisplayMode.contains("icon") {
                    if isSplitView {
                        // Show multiple favicons for split view
                        HStack(spacing: 2) {
                            ForEach(Array(allTabsInGroup.prefix(4)), id: \.id) { tab in
                                Favicon(url: tab.url)
                                    .frame(width: 12, height: 12)
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
                            Favicon(url: firstTab.url)
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
                            Text(tabsManager.linksWithTitles[firstTab.url] ?? firstTab.url)
                                .foregroundStyle(Color(hex: space.textColor))
                                .lineLimit(1)
                                .onAppear {
                                    Task { await tabsManager.fetchTitlesIfNeeded(for: [firstTab.url]) }
                                }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                await selectTabGroup()
            }
        }
        .onHover { hover in
            withAnimation {
                // Handle hover state for TabGroup
            }
        }
        .contextMenu(menuItems: {
            contextMenuItems
        })
        .onDrag {
            createDragProvider()
        }
        .onDrop(of: [UTType.text], delegate: TabGroupDropDelegate(tabGroup: tabGroup, space: space, draggingTabID: $draggingTabID, modelContext: modelContext))
    }
    
    // MARK: - Computed Properties
    
    private var isSplitView: Bool {
        let totalTabs = tabGroup.tabRows.reduce(0) { $0 + $1.tabs.count }
        return totalTabs > 1 || tabGroup.tabRows.count > 1
    }
    
    private var firstTab: StoredTab? {
        return tabGroup.tabRows.first?.tabs.first
    }
    
    private var allTabsInGroup: [StoredTab] {
        return tabGroup.tabRows.flatMap { $0.tabs.sorted { $0.orderIndex < $1.orderIndex } }
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
        let replacement = storageManager.closeTabGroup(tabGroup: tabGroup, modelContext: modelContext)
        uiViewModel.currentSelectedTab = replacement?.id ?? ""
    }
    
    private func createDragProvider() -> NSItemProvider {
        let tabID = firstTab?.id ?? tabGroup.id
        draggingTabID = tabID
        let provider = NSItemProvider()
        provider.registerDataRepresentation(forTypeIdentifier: UTType.text.identifier, visibility: .ownProcess) { [tabID] completion in
            completion(Data(tabID.utf8), nil)
            return nil
        }
        return provider
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
                Label("Close Tab Group", systemImage: "rectangle.badge.xmark")
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