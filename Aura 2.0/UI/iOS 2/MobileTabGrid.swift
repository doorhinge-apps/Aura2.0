import SwiftUI

//struct MobileTabGrid: View {
//    var space: SpaceData
//    @Binding var draggingTabID: String?
////    let columns = [GridItem(.adaptive(minimum: 75))]
//    let columns = [GridItem(), GridItem()]
//    
//    @State var currentTabType: TabType
//
//    var body: some View {
//        LazyVGrid(columns: columns, spacing: 10) {
//            let orderedGroups = (currentTabType == .favorites ? space.favoriteTabGroups ?? []: currentTabType == .pinned ? space.pinnedTabGroups ?? []: space.primaryTabGroups ?? [])
//                .filter { $0.hasNonTemporaryTabs }
//                .sorted { $0.orderIndex < $1.orderIndex }
//            ForEach(orderedGroups, id: \.id) { tabGroup in
//                GeometryReader { geo in
//                    MobileTabGroup(tabGroup: tabGroup, space: space, draggingTabID: $draggingTabID)
//                        .frame(width: geo.size.width, height: geo.size.width * (4/3) + 50)
//                        .overlay {
//                            RoundedRectangle(cornerRadius: 15)
//                                .frame(width: geo.size.width, height: geo.size.width * (4/3) + 50)
//                        }
//                }
//            }
//        }.padding(5)
//    }
//}

struct MobileTabGrid: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var uiViewModel: UIViewModel
    @EnvironmentObject var tabsManager: TabsManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    var space: SpaceData
    @Binding var draggingTabID: String?
    let columns = [GridItem(), GridItem()]
    
    @State var currentTabType: TabType
    
    let namespace: Namespace.ID

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            let orderedGroups = (currentTabType == .favorites ? space.favoriteTabGroups ?? []: currentTabType == .pinned ? space.pinnedTabGroups ?? []: space.primaryTabGroups ?? [])
                .filter { $0.hasNonTemporaryTabs }
                .sorted { $0.orderIndex < $1.orderIndex }
            ForEach(orderedGroups, id: \.id) { tabGroup in
                MobileTabGroup(tabGroup: tabGroup, space: space, draggingTabID: $draggingTabID, namespace: namespace)
//                    .zIndex(draggingTabID ?? "" == tabGroup.id.description ? 100: 0)
                    .zIndex(draggingTabID ?? "" == tabGroup.id.description ? 100: 0)
                    .animation(.easeInOut(duration: 0.1), value: draggingTabID)
                    .aspectRatio(3/5, contentMode: .fit)
//                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 0)
                    .onChange(of: draggingTabID) { old, new in
                        print("Dragging Tab: \(draggingTabID ?? "")")
                        print("Current Tab: \(tabGroup.id.description)")
                    }
            }
        }.padding(5)
    }
}
