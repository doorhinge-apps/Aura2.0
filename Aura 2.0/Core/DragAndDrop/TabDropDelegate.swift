import SwiftUI
import SwiftData

struct TabDropDelegate: DropDelegate {
    let tab: StoredTab
    @Binding var tabs: [StoredTab]
    @Binding var draggedTab: StoredTab?
    var modelContext: ModelContext

    func dropEntered(info: DropInfo) {
        guard let dragged = draggedTab,
              dragged != tab,
              let from = tabs.firstIndex(of: dragged),
              let to = tabs.firstIndex(of: tab) else { return }

        // Real-time reorder preview
        withAnimation {
            tabs.move(fromOffsets: IndexSet(integer: from), toOffset: to)
            updateOrder()
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedTab = nil
        updateOrder()
        try? modelContext.save()
        return true
    }

    private func updateOrder() {
        for (idx, t) in tabs.enumerated() {
            t.orderIndex = idx
        }
    }
}
