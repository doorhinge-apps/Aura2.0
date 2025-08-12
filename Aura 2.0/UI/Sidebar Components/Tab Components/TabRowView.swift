import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TabRowView: View {
    var tab: StoredTab
    var space: SpaceData
    var tabType: TabType
    @Binding var draggingTabID: String?

    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.001))

            if !storageManager.currentTabs.isEmpty {
                if !storageManager.currentTabs[0].isEmpty {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(uiViewModel.currentSelectedTab == tab.id ? 0.5 : uiViewModel.currentHoverTab == tab ? 0.25 : 0.001))
                        .animation(.easeInOut, value: storageManager.currentTabs[0][0].storedTab == tab)
                }
            }

            HStack {
                Favicon(url: tab.url)
                Text(tabsManager.linksWithTitles[tab.url] ?? tab.url)
                    .foregroundStyle(Color(hex: space.textColor))
                    .lineLimit(1)
                    .onAppear {
                        Task { await tabsManager.fetchTitlesIfNeeded(for: [tab.url]) }
                    }
                Spacer()

                if uiViewModel.currentSelectedTab == tab.id || uiViewModel.currentHoverTab?.id ?? "rat" == tab.id {
                    Button {
                        withAnimation {
                            uiViewModel.currentSelectedTab = storageManager.closeTab(tabObject: tab, tabType: tabType)?.id ?? ""
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                            .foregroundStyle(Color(hex: storageManager.selectedSpace?.textColor ?? "ffffff"))
                            .opacity(uiViewModel.hoveringID == "addNewSpace" ? 1.0 : 0.5)
                            .padding(.trailing, 10)
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 5)
        }
        .contentShape(Rectangle())
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
                } else {
                    uiViewModel.currentHoverTab = tab
                }
            }
        }
        .contextMenu(menuItems: {
            Button {
                UIPasteboard.general.string = tab.url
            } label: {
                Label("Copy URL", systemImage: "link")
            }

            Button {
                withAnimation {
                    uiViewModel.currentSelectedTab = storageManager.closeTab(tabObject: tab, tabType: tabType)?.id ?? ""
                }
            } label: {
                Label("Close Tab", systemImage: "rectangle.badge.xmark")
            }
            
            Divider()

            Button {
                withAnimation {
                    storageManager.updateTabType(
                        for: tab,
                        to: tab.tabType == .favorites ? .primary : .favorites,
                        modelContext: modelContext
                    )
                }
            } label: {
                Label(tab.tabType == .favorites ? "Unfavorite" : "Favorite",
                      systemImage: tab.tabType == .favorites ? "star.fill" : "star")
            }

            Button {
                withAnimation {
                    storageManager.updateTabType(
                        for: tab,
                        to: tab.tabType == .pinned ? .primary : .pinned,
                        modelContext: modelContext
                    )
                }
            } label: {
                Label(tab.tabType == .pinned ? "Unpin" : "Pin",
                      systemImage: tab.tabType == .pinned ? "pin.fill" : "pin")
            }
        })
        .onDrag {
            let tabID = tab.id
            draggingTabID = tabID
            let provider = NSItemProvider()
            provider.registerDataRepresentation(forTypeIdentifier: UTType.text.identifier, visibility: .ownProcess) { [tabID] completion in
                completion(Data(tabID.utf8), nil)
                return nil
            }
            return provider
        }
        .onDrop(of: [UTType.text], delegate: TabDropDelegate(tab: tab, space: space, tabType: tabType, draggingTabID: $draggingTabID, modelContext: modelContext))
    }
}
