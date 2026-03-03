import Cocoa

class RulerTool {
    
    var isVisible: Bool = false
    var position: CGPoint = CGPoint(x: 400, y: 300)
    var angle: CGFloat = 0  // radians
    var length: CGFloat = 500
    
    var startPoint: CGPoint {
        let halfLength = length / 2
        return CGPoint(
            x: position.x - cos(angle) * halfLength,
            y: position.y - sin(angle) * halfLength
        )
    }
    
    var endPoint: CGPoint {
        let halfLength = length / 2
        return CGPoint(
            x: position.x + cos(angle) * halfLength,
            y: position.y + sin(angle) * halfLength
        )
    }
    
    /// Projects a point onto the ruler edge, constraining drawing to a straight line.
    func constrainPoint(_ point: CGPoint) -> CGPoint {
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let lengthSq = dx * dx + dy * dy
        guard lengthSq > 0 else { return startPoint }
        
        var t = ((point.x - startPoint.x) * dx + (point.y - startPoint.y) * dy) / lengthSq
        t = max(0, min(1, t))
        
        return CGPoint(
            x: startPoint.x + t * dx,
            y: startPoint.y + t * dy
        )
    }
    
    /// Returns distance from a point to the ruler line.
    func distanceToRuler(from point: CGPoint) -> CGFloat {
        let projected = constrainPoint(point)
        return hypot(point.x - projected.x, point.y - projected.y)
    }
    
    /// Hit test: is the point close enough to drag the ruler?
    func hitTest(_ point: CGPoint, threshold: CGFloat = 30) -> Bool {
        return distanceToRuler(from: point) <= threshold
    }
    
    func move(to point: CGPoint) {
        position = point
    }
    
    func rotate(by delta: CGFloat) {
        angle += delta
    }
    
    func toggle() {
        isVisible.toggle()
    }
}
