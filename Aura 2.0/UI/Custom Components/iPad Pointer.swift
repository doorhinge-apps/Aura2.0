//
//  iPad Pointer.swift
//  Aura 2.0
//
//  Created on 13/9/25.
//

import SwiftUI
import UIKit

struct RoundedOutwardTriangles: Shape {
    var gap: CGFloat = 8
    var cornerRadius: CGFloat = 4

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(gap, cornerRadius) }
        set {
            gap = newValue.first
            cornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let clampedGap = min(max(gap, 0), rect.width * 0.9)
        let midY = rect.midY
        let sideLength = min(rect.height, (rect.width - clampedGap) / 2)
        let triHeight = sideLength * sqrt(3) / 2

        // Helper to draw a rounded triangle given 3 points
        func roundedTriangle(_ points: [CGPoint], into path: inout Path) {
            guard points.count == 3 else { return }

            let r = min(cornerRadius, sideLength / 3)

            for i in 0..<3 {
                let p0 = points[i]
                let p1 = points[(i + 1) % 3]
                let p2 = points[(i + 2) % 3]

                let v1 = CGVector(dx: p0.x - p1.x, dy: p0.y - p1.y)
                let v2 = CGVector(dx: p2.x - p1.x, dy: p2.y - p1.y)

                let l1 = sqrt(v1.dx * v1.dx + v1.dy * v1.dy)
                let l2 = sqrt(v2.dx * v2.dx + v2.dy * v2.dy)

                let u1 = CGPoint(x: p1.x + v1.dx / l1 * r, y: p1.y + v1.dy / l1 * r)
                let u2 = CGPoint(x: p1.x + v2.dx / l2 * r, y: p1.y + v2.dy / l2 * r)

                if i == 0 {
                    path.move(to: u1)
                } else {
                    path.addLine(to: u1)
                }

                path.addQuadCurve(to: u2, control: p1)
            }

            path.closeSubpath()
        }

        // Left outward triangle (pointing left)
        let leftTip = CGPoint(x: rect.minX, y: midY)
        let leftTop = CGPoint(x: rect.midX - clampedGap / 2, y: midY - triHeight / 2)
        let leftBottom = CGPoint(x: rect.midX - clampedGap / 2, y: midY + triHeight / 2)
        roundedTriangle([leftTip, leftTop, leftBottom], into: &path)

        // Right outward triangle (pointing right)
        let rightTip = CGPoint(x: rect.maxX, y: midY)
        let rightTop = CGPoint(x: rect.midX + clampedGap / 2, y: midY - triHeight / 2)
        let rightBottom = CGPoint(x: rect.midX + clampedGap / 2, y: midY + triHeight / 2)
        roundedTriangle([rightTip, rightTop, rightBottom], into: &path)

        return path
    }
}

@available(iOS 13.4, *)
struct IPadPointerModifier: ViewModifier {
    enum Style {
        case roundedRect(cornerRadius: CGFloat)
        case verticalBeam(length: CGFloat)
        case horizontalBeam(length: CGFloat)
        case hidden
    }

    let style: Style

    func body(content: Content) -> some View {
        content.overlay(
            PointerInteractionRepresentable(style: style)
                .allowsHitTesting(false)
        )
    }
}

@available(iOS 13.4, *)
private struct PointerInteractionRepresentable: UIViewRepresentable {
    let style: IPadPointerModifier.Style

    func makeCoordinator() -> Coordinator { Coordinator(style: style) }

    func makeUIView(context: Context) -> UIView {
        let v = UIView(frame: .zero)
        let interaction = UIPointerInteraction(delegate: context.coordinator)
        v.addInteraction(interaction)
        context.coordinator.host = v
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.style = style
    }

    final class Coordinator: NSObject, UIPointerInteractionDelegate {
        weak var host: UIView?
        var style: IPadPointerModifier.Style

        init(style: IPadPointerModifier.Style) {
            self.style = style
        }

        func pointerInteraction(_ interaction: UIPointerInteraction,
                                regionFor request: UIPointerRegionRequest,
                                defaultRegion: UIPointerRegion) -> UIPointerRegion? {
            guard let host else { return nil }
            return UIPointerRegion(rect: host.bounds, identifier: nil)
        }

        func pointerInteraction(_ interaction: UIPointerInteraction,
                                styleFor region: UIPointerRegion) -> UIPointerStyle? {
            guard let host else { return nil }
            switch style {
            case .roundedRect(let radius):
                let preview = UITargetedPreview(view: host)
                let effect = UIPointerEffect.lift(preview)
                let shape = UIPointerShape.roundedRect(host.bounds, radius: radius)
                return UIPointerStyle(effect: effect, shape: shape)

            case .verticalBeam(let length):
                let shape = UIPointerShape.verticalBeam(length: length)
                return UIPointerStyle(shape: shape)

            case .horizontalBeam(let length):
                let shape = UIPointerShape.horizontalBeam(length: length)
                return UIPointerStyle(shape: shape)

            case .hidden:
                return .hidden()
            }
        }
    }
}

extension View {
    @available(iOS 13.4, *)
    func iPadPointer(_ style: IPadPointerModifier.Style) -> some View {
        modifier(IPadPointerModifier(style: style))
    }
}

