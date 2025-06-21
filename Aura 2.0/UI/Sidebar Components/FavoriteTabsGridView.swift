import SwiftUI

struct FavoriteTabsGridView: View {
    var space: SpaceData
    @Binding var draggingTabID: String?
    let columns = [GridItem(.adaptive(minimum: 75))]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            let orderedTabs = space.favoriteTabs.sorted { $0.orderIndex < $1.orderIndex }
            ForEach(orderedTabs, id: \.id) { tab in
                TabRowView(tab: tab, space: space, tabType: .favorites, draggingTabID: $draggingTabID)
            }
        }
    }
}
