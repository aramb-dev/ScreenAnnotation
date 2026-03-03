import Cocoa

/// Laser Pointer Tool — bright dot/trail that fades over 2 seconds.
struct LaserPointerTool: DrawingTool {
    let penType: PenType = .laserPointer
    var displayName: String { "Laser Pointer" }
    
    static let fadeDuration: TimeInterval = 2.0
    
    func createStroke(color: NSColor, width: CGFloat) -> Stroke {
        Stroke(penType: .laserPointer, color: color, width: width, opacity: 1.0)
    }
    
    func processPoint(_ point: StrokePoint, in stroke: Stroke) -> StrokePoint {
        var modified = point
        modified.pressure = 1.0 // Constant width
        return modified
    }
    
    func finalizeStroke(_ stroke: Stroke) {
        if stroke.points.count >= 4 {
            stroke.smoothedPoints = StrokeSmoothing.smooth(points: stroke.points, subdivisions: 4)
        }
    }
}
