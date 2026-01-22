import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }
        
        totalHeight = currentY + lineHeight
        
        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

/// A flow layout that only shows items that fit on a single row.
/// Items that would wrap to a second row are hidden (placed offscreen with zero size).
struct SingleRowFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        
        for (index, placement) in result.placements.enumerated() {
            if placement.visible {
                subviews[index].place(
                    at: CGPoint(x: bounds.minX + placement.position.x, y: bounds.minY + placement.position.y),
                    proposal: .unspecified
                )
            } else {
                subviews[index].place(
                    at: CGPoint(x: -10000, y: -10000),
                    proposal: .zero
                )
            }
        }
    }
    
    private struct Placement {
        let position: CGPoint
        let visible: Bool
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, placements: [Placement]) {
        let maxWidth = proposal.width ?? .infinity
        var placements: [Placement] = []
        var currentX: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                placements.append(Placement(position: .zero, visible: false))
            } else {
                placements.append(Placement(position: CGPoint(x: currentX, y: 0), visible: true))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
        }
        
        let totalWidth = max(0, currentX - spacing)
        return (CGSize(width: totalWidth, height: lineHeight), placements)
    }
}
