import Cocoa

/// Calligraphy Tool — varying thickness based on stroke angle/direction; mimics nib calligraphy pen.
struct CalligraphyTool: DrawingTool {
    let penType: PenType = .calligraphy
    var displayName: String { "Calligraphy" }
    
    /// Nib angle in radians (45° by default, like a traditional calligraphy pen)
    var nibAngle: CGFloat = .pi / 4
    
    func createStroke(color: NSColor, width: CGFloat) -> Stroke {
        return Stroke(penType: .calligraphy, color: color, width: width, opacity: 0.95)
    }
    
    func processPoint(_ point: StrokePoint, in stroke: Stroke) -> StrokePoint {
        guard stroke.points.count >= 1 else { return point }
        
        let prevPoint = stroke.points.last!
        var modified = point
        
        // Calculate stroke direction
        let dx = point.position.x - prevPoint.position.x
        let dy = point.position.y - prevPoint.position.y
        let strokeAngle = atan2(dy, dx)
        
        // Calligraphy effect: width varies based on angle between stroke direction and nib angle
        // Perpendicular to nib = thickest, parallel = thinnest
        let angleDiff = abs(strokeAngle - nibAngle)
        let normalizedAngle = abs(sin(angleDiff))
        
        // Map to pressure: thin at 0° (parallel), thick at 90° (perpendicular)
        modified.pressure = 0.2 + normalizedAngle * 0.8
        
        return modified
    }
    
    func finalizeStroke(_ stroke: Stroke) {
        if stroke.points.count >= 4 {
            stroke.smoothedPoints = StrokeSmoothing.smooth(points: stroke.points, subdivisions: 5)
        }
    }
}
