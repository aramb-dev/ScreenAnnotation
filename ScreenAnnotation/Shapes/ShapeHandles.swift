import Cocoa

enum HandlePosition: Int, CaseIterable {
    case topLeft = 0
    case topCenter
    case topRight
    case middleRight
    case bottomRight
    case bottomCenter
    case bottomLeft
    case middleLeft
}

class ShapeHandleManager {
    
    private let handleSize: CGFloat = 10
    private var activeHandle: HandlePosition?
    private var initialBounds: CGRect = .zero
    private var initialMousePos: CGPoint = .zero
    
    func hitTest(point: CGPoint, shape: ShapeAnnotation) -> HandlePosition? {
        for (index, handlePos) in shape.handlePositions.enumerated() {
            let handleRect = CGRect(
                x: handlePos.x - handleSize / 2,
                y: handlePos.y - handleSize / 2,
                width: handleSize,
                height: handleSize
            )
            if handleRect.contains(point) {
                return HandlePosition(rawValue: index)
            }
        }
        return nil
    }
    
    func beginResize(handle: HandlePosition, shape: ShapeAnnotation, mousePosition: CGPoint) {
        activeHandle = handle
        initialBounds = shape.bounds
        initialMousePos = mousePosition
    }
    
    func continueResize(to point: CGPoint, shape: ShapeAnnotation) {
        guard let handle = activeHandle else { return }
        
        let dx = point.x - initialMousePos.x
        let dy = point.y - initialMousePos.y
        
        var newBounds = initialBounds
        
        switch handle {
        case .topLeft:
            newBounds.origin.x += dx
            newBounds.origin.y += dy
            newBounds.size.width -= dx
            newBounds.size.height -= dy
        case .topCenter:
            newBounds.origin.y += dy
            newBounds.size.height -= dy
        case .topRight:
            newBounds.origin.y += dy
            newBounds.size.width += dx
            newBounds.size.height -= dy
        case .middleRight:
            newBounds.size.width += dx
        case .bottomRight:
            newBounds.size.width += dx
            newBounds.size.height += dy
        case .bottomCenter:
            newBounds.size.height += dy
        case .bottomLeft:
            newBounds.origin.x += dx
            newBounds.size.width -= dx
            newBounds.size.height += dy
        case .middleLeft:
            newBounds.origin.x += dx
            newBounds.size.width -= dx
        }
        
        // Ensure minimum size
        newBounds.size.width = max(10, newBounds.size.width)
        newBounds.size.height = max(10, newBounds.size.height)
        
        // Rebuild shape path for the new bounds
        rebuildPath(for: shape, newBounds: newBounds)
    }
    
    func endResize() {
        activeHandle = nil
    }
    
    private func rebuildPath(for shape: ShapeAnnotation, newBounds: CGRect) {
        switch shape.shapeType {
        case .rectangle:
            shape.path = NSBezierPath(rect: newBounds)
        case .circle, .ellipse:
            shape.path = NSBezierPath(ovalIn: newBounds)
        case .triangle:
            let path = NSBezierPath()
            path.move(to: CGPoint(x: newBounds.midX, y: newBounds.maxY))
            path.line(to: CGPoint(x: newBounds.minX, y: newBounds.minY))
            path.line(to: CGPoint(x: newBounds.maxX, y: newBounds.minY))
            path.close()
            shape.path = path
        case .star:
            shape.path = ShapeFactory.createStar(
                center: CGPoint(x: newBounds.midX, y: newBounds.midY),
                outerRadius: min(newBounds.width, newBounds.height) / 2,
                innerRadius: min(newBounds.width, newBounds.height) / 4
            )
        case .speechBubble:
            shape.path = ShapeFactory.createSpeechBubble(newBounds)
        default:
            break
        }
        shape.bounds = newBounds
    }
}
