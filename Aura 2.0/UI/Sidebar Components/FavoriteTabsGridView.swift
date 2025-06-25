import SwiftUI

struct FavoriteTabsGridView: View {
    var space: SpaceData
    @Binding var draggingTabID: String?
    let columns = [GridItem(.adaptive(minimum: 75))]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            let orderedGroups = (space.favoriteTabGroups ?? [])
                .filter { $0.hasNonTemporaryTabs }
                .sorted { $0.orderIndex < $1.orderIndex }
            ForEach(orderedGroups, id: \.id) { tabGroup in
                TabGroupFavoriteView(tabGroup: tabGroup, space: space, draggingTabID: $draggingTabID)
            }
        }.padding(5)
    }
}
