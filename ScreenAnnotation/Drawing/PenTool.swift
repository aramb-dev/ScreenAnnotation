import Cocoa

/// Pen Tool — thin, precise line; "Virtual Flair Pen"; pressure → width; full opacity.
struct PenTool: DrawingTool {
    let penType: PenType = .pen
    var displayName: String { "Pen" }
    
    func createStroke(color: NSColor, width: CGFloat) -> Stroke {
        return Stroke(penType: .pen, color: color, width: width, opacity: 1.0)
    }
    
    func processPoint(_ point: StrokePoint, in stroke: Stroke) -> StrokePoint {
        return point
    }
}
