import Cocoa

/// Highlighter Tool — broad, semi-transparent marker; translucent wash effect; multiply blend.
struct HighlighterTool: DrawingTool {
    let penType: PenType = .highlighter
    var displayName: String { "Highlighter" }
    
    func createStroke(color: NSColor, width: CGFloat) -> Stroke {
        return Stroke(penType: .highlighter, color: color, width: max(width, 15.0), opacity: 0.3)
    }
    
    func processPoint(_ point: StrokePoint, in stroke: Stroke) -> StrokePoint {
        // Fixed width regardless of pressure
        var modified = point
        modified.pressure = 1.0
        return modified
    }
}
