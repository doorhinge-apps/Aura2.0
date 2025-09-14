import SwiftUI
import UIKit

// Safe ViewModifier to hide cursor on hover (App Store compatible)
struct SafeHideCursorOnHover: ViewModifier {
    @State private var isHovering = false
    
    func body(content: Content) -> some View {
        content
            .background(HiddenCursorView())
            .onContinuousHover { phase in
                switch phase {
                case .active(_):
                    isHovering = true
                case .ended:
                    isHovering = false
                }
            }
    }
}

// UIViewRepresentable that handles the cursor hiding
struct HiddenCursorView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        if #available(iOS 13.4, *) {
            let interaction = UIPointerInteraction(delegate: context.coordinator)
            view.addInteraction(interaction)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIPointerInteractionDelegate {
        @available(iOS 13.4, *)
        func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
            // Returning nil makes the cursor invisible!
            return nil
        }
    }
}

// Extension to make the modifier easy to use
extension View {
    /// Hides the cursor when hovering over this view on iPadOS
    func hideCursorOnHover() -> some View {
        self.modifier(SafeHideCursorOnHover())
    }
}
