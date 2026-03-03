import Cocoa

/// Represents a recognized or inserted clean vector shape.
class ShapeAnnotation: Identifiable {
    let id = UUID()
    var shapeType: RecognizedShapeType
    var path: NSBezierPath
    var borderColor: NSColor
    var fillColor: NSColor?
    var borderWidth: CGFloat
    var opacity: CGFloat
    var bounds: CGRect
    var rotation: CGFloat = 0
    
    init(shapeType: RecognizedShapeType, path: NSBezierPath, borderColor: NSColor, fillColor: NSColor? = nil, borderWidth: CGFloat = 2.0, opacity: CGFloat = 1.0) {
        self.shapeType = shapeType
        self.path = path
        self.borderColor = borderColor
        self.fillColor = fillColor
        self.borderWidth = borderWidth
        self.opacity = opacity
        self.bounds = path.bounds
    }
    
    var handlePositions: [CGPoint] {
        let rect = bounds
        return [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.midX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.midY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.midX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.midY),
        ]
    }
}

/// Factory for creating common shapes.
struct ShapeFactory {
    
    static func createLine(from start: CGPoint, to end: CGPoint) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: start)
        path.line(to: end)
        return path
    }
    
    static func createArrow(from start: CGPoint, to end: CGPoint, headLength: CGFloat = 15) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: start)
        path.line(to: end)
        
        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowAngle: CGFloat = .pi / 6
        
        let left = CGPoint(
            x: end.x - headLength * cos(angle - arrowAngle),
            y: end.y - headLength * sin(angle - arrowAngle)
        )
        let right = CGPoint(
            x: end.x - headLength * cos(angle + arrowAngle),
            y: end.y - headLength * sin(angle + arrowAngle)
        )
        
        path.move(to: end)
        path.line(to: left)
        path.move(to: end)
        path.line(to: right)
        
        return path
    }
    
    static func createCircle(center: CGPoint, radius: CGFloat) -> NSBezierPath {
        return NSBezierPath(ovalIn: CGRect(
            x: center.x - radius, y: center.y - radius,
            width: radius * 2, height: radius * 2
        ))
    }
    
    static func createRectangle(_ rect: CGRect) -> NSBezierPath {
        return NSBezierPath(rect: rect)
    }
    
    static func createRoundedRectangle(_ rect: CGRect, cornerRadius: CGFloat = 8) -> NSBezierPath {
        return NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    }
    
    static func createStar(center: CGPoint, outerRadius: CGFloat, innerRadius: CGFloat, points: Int = 5) -> NSBezierPath {
        let path = NSBezierPath()
        let angleStep = .pi / CGFloat(points)
        
        for i in 0..<(points * 2) {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let angle = CGFloat(i) * angleStep - .pi / 2
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.line(to: point)
            }
        }
        path.close()
        return path
    }
    
    static func createSpeechBubble(_ rect: CGRect) -> NSBezierPath {
        let path = NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10)
        
        // Add tail
        let tailPath = NSBezierPath()
        let tailStart = CGPoint(x: rect.minX + rect.width * 0.2, y: rect.minY)
        let tailEnd = CGPoint(x: rect.minX + rect.width * 0.1, y: rect.minY - 20)
        let tailBack = CGPoint(x: rect.minX + rect.width * 0.35, y: rect.minY)
        
        tailPath.move(to: tailStart)
        tailPath.line(to: tailEnd)
        tailPath.line(to: tailBack)
        
        path.append(tailPath)
        return path
    }
}
