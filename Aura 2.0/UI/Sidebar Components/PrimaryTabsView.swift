import SwiftUI

struct PrimaryTabsView: View {
    var space: SpaceData
    @Binding var draggingTabID: String?

    var body: some View {
        VStack {
            let orderedTabs = space.primaryTabs.sorted { $0.orderIndex > $1.orderIndex }
            ForEach(orderedTabs, id: \.id) { tab in
                TabRowView(tab: tab, space: space, tabType: .primary, draggingTabID: $draggingTabID)
            }
        }
    }
}
