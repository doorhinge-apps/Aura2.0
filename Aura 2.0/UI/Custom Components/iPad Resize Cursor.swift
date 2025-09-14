import SwiftUI
import UIKit

// MARK: - UIKit Resize Pointer View
class ResizePointerView: UIView {
    var isHoveringCallback: ((Bool) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInteractions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupInteractions()
    }
    
    private func setupInteractions() {
        backgroundColor = .clear
        
        // Add pointer interaction for iPadOS 13.4+
        if #available(iOS 13.4, *) {
            let pointerInteraction = UIPointerInteraction(delegate: self)
            addInteraction(pointerInteraction)
        }
        
        // Add hover gesture recognizer
        let hoverGesture = UIHoverGestureRecognizer(target: self, action: #selector(handleHover(_:)))
        addGestureRecognizer(hoverGesture)
    }
    
    @objc private func handleHover(_ gesture: UIHoverGestureRecognizer) {
        switch gesture.state {
        case .began:
            isHoveringCallback?(true)
        case .ended, .cancelled:
            isHoveringCallback?(false)
        default:
            break
        }
    }
}

// MARK: - UIPointerInteractionDelegate
@available(iOS 13.4, *)
extension ResizePointerView: UIPointerInteractionDelegate {
    func pointerInteraction(_ interaction: UIPointerInteraction, regionFor request: UIPointerRegionRequest, defaultRegion: UIPointerRegion) -> UIPointerRegion? {
        return defaultRegion
    }
    
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        // Create targeted preview
        let targetedPreview = UITargetedPreview(view: self)
        
        // Use lift effect for visual feedback
        let effect = UIPointerEffect.lift(targetedPreview)
        
        // Use horizontal beam shape to indicate resize capability
        let shape = UIPointerShape.horizontalBeam(length: 30)
        
        return UIPointerStyle(effect: effect, shape: shape)
    }
}

// MARK: - SwiftUI UIViewRepresentable
struct ResizePointerRepresentable: UIViewRepresentable {
    @Binding var isHovering: Bool
    
    func makeUIView(context: Context) -> ResizePointerView {
        let view = ResizePointerView()
        view.isHoveringCallback = { hovering in
            DispatchQueue.main.async {
                self.isHovering = hovering
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: ResizePointerView, context: Context) {
        // No updates needed
    }
}

// MARK: - SwiftUI View Modifier
struct ResizePointerModifier: ViewModifier {
    @State private var isHovering = false
    var showVisualFeedback: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ResizePointerRepresentable(isHovering: $isHovering)
                    .allowsHitTesting(false)
            )
            .scaleEffect(showVisualFeedback && isHovering ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
    }
}

// MARK: - View Extension
extension View {
    /// Adds iPadOS pointer interaction with resize indication
    /// - Parameter showVisualFeedback: Whether to show scale animation on hover
    func resizePointer(showVisualFeedback: Bool = true) -> some View {
        self.modifier(ResizePointerModifier(showVisualFeedback: showVisualFeedback))
    }
}
