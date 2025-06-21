import SwiftUI

struct PinnedTabsView: View {
    var space: SpaceData
    @Binding var draggingTabID: String?

    var body: some View {
        VStack {
            let orderedTabs = space.pinnedTabs.sorted { $0.orderIndex < $1.orderIndex }
            ForEach(orderedTabs, id: \.id) { tab in
                TabRowView(tab: tab, space: space, tabType: .pinned, draggingTabID: $draggingTabID)
            }
        }
    }
}
