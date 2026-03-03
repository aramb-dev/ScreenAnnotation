import Cocoa

struct StrokePoint {
    var position: CGPoint
    var pressure: CGFloat
    var tilt: CGFloat
    var rotation: CGFloat
    var timestamp: TimeInterval
    
    init(position: CGPoint, pressure: CGFloat = 1.0, tilt: CGFloat = 0, rotation: CGFloat = 0, timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        self.position = position
        self.pressure = pressure
        self.tilt = tilt
        self.rotation = rotation
        self.timestamp = timestamp
    }
}

enum PenType: String, CaseIterable, Identifiable {
    case pen
    case fineTip
    case highlighter
    case pencil
    case crayon
    case calligraphy
    case watercolor
    case laserPointer
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .pen: return "Pen"
        case .fineTip: return "Fine Tip"
        case .highlighter: return "Highlighter"
        case .pencil: return "Pencil"
        case .crayon: return "Crayon"
        case .calligraphy: return "Calligraphy"
        case .watercolor: return "Watercolor"
        case .laserPointer: return "Laser Pointer"
        }
    }
    
    var defaultWidth: CGFloat {
        switch self {
        case .pen: return 3.0
        case .fineTip: return 1.0
        case .highlighter: return 20.0
        case .pencil: return 2.0
        case .crayon: return 6.0
        case .calligraphy: return 4.0
        case .watercolor: return 12.0
        case .laserPointer: return 5.0
        }
    }
    
    func widthMultiplier(pressure: CGFloat) -> CGFloat {
        switch self {
        case .pen:
            return 0.5 + pressure * 1.5
        case .fineTip:
            return 0.8 + pressure * 0.4
        case .highlighter:
            return 1.0
        case .pencil:
            return 0.6 + pressure * 0.8
        case .crayon:
            return 0.7 + pressure * 0.6
        case .calligraphy:
            return 1.0 // Width controlled by angle, not pressure
        case .watercolor:
            return 0.8 + pressure * 0.4
        case .laserPointer:
            return 1.0
        }
    }
    
    func opacity(pressure: CGFloat) -> CGFloat {
        switch self {
        case .pen: return 1.0
        case .fineTip: return 1.0
        case .highlighter: return 0.3
        case .pencil: return 0.4 + pressure * 0.5
        case .crayon: return 0.7 + pressure * 0.3
        case .calligraphy: return 0.9
        case .watercolor: return 0.2 + pressure * 0.3
        case .laserPointer: return 1.0
        }
    }
}

class Stroke: Identifiable {
    let id = UUID()
    var points: [StrokePoint] = []
    var smoothedPoints: [StrokePoint] = []
    var penType: PenType
    var color: NSColor
    var width: CGFloat
    var opacity: CGFloat
    var createdAt: TimeInterval
    
    // For laser pointer fade
    var fadeAlpha: CGFloat = 1.0
    
    // For shape recognition
    var isRecognizedShape: Bool = false
    var recognizedShapePath: NSBezierPath?
    
    init(penType: PenType, color: NSColor, width: CGFloat, opacity: CGFloat = 1.0) {
        self.penType = penType
        self.color = color
        self.width = width
        self.opacity = opacity
        self.createdAt = ProcessInfo.processInfo.systemUptime
    }
    
    func addPoint(_ point: StrokePoint) {
        points.append(point)
    }
    
    var activePoints: [StrokePoint] {
        smoothedPoints.isEmpty ? points : smoothedPoints
    }
    
    func translate(dx: CGFloat, dy: CGFloat) {
        for i in points.indices { points[i].position.x += dx; points[i].position.y += dy }
        for i in smoothedPoints.indices { smoothedPoints[i].position.x += dx; smoothedPoints[i].position.y += dy }
    }
    
    func deepCopy() -> Stroke {
        let copy = Stroke(penType: penType, color: color, width: width, opacity: opacity)
        copy.points = points
        copy.smoothedPoints = smoothedPoints
        copy.createdAt = createdAt
        copy.fadeAlpha = fadeAlpha
        copy.isRecognizedShape = isRecognizedShape
        copy.recognizedShapePath = recognizedShapePath?.copy() as? NSBezierPath
        return copy
    }

    var boundingRect: CGRect {
        guard !points.isEmpty else { return .zero }
        let halfWidth = width / 2.0
        var minX = CGFloat.infinity, minY = CGFloat.infinity
        var maxX = -CGFloat.infinity, maxY = -CGFloat.infinity
        for p in activePoints {
            minX = min(minX, p.position.x - halfWidth)
            minY = min(minY, p.position.y - halfWidth)
            maxX = max(maxX, p.position.x + halfWidth)
            maxY = max(maxY, p.position.y + halfWidth)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
