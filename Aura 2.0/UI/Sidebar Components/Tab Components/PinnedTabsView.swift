import SwiftUI

struct PinnedTabsView: View {
    var space: SpaceData
    @Binding var draggingTabID: String?

    var body: some View {
        VStack {
            let orderedGroups = (space.pinnedTabGroups ?? [])
                .filter { $0.hasNonTemporaryTabs }
                .sorted { $0.orderIndex < $1.orderIndex }
            ForEach(orderedGroups, id: \.id) { tabGroup in
                TabGroupRowView(tabGroup: tabGroup, space: space, draggingTabID: $draggingTabID)
            }
        }
    }
}
