import Cocoa

/// Watercolor Tool — soft, translucent brush stroke; feathered edges; hue blending on overlap.
struct WatercolorTool: DrawingTool {
    let penType: PenType = .watercolor
    var displayName: String { "Watercolor" }
    
    func createStroke(color: NSColor, width: CGFloat) -> Stroke {
        return Stroke(penType: .watercolor, color: color, width: max(width, 10.0), opacity: 0.35)
    }
    
    func processPoint(_ point: StrokePoint, in stroke: Stroke) -> StrokePoint {
        var modified = point
        // Watercolor has soft, gentle pressure response
        modified.pressure = 0.5 + point.pressure * 0.3
        return modified
    }
    
    func finalizeStroke(_ stroke: Stroke) {
        // Higher subdivision for smoother watercolor edges
        stroke.smoothedPoints = stroke.points.count >= 4
            ? StrokeSmoothing.smooth(points: stroke.points, subdivisions: 6)
            : stroke.points
        applyWatercolorEffect(to: stroke)
    }
    
    private func applyWatercolorEffect(to stroke: Stroke) {
        // Operate on smoothedPoints directly (always populated by finalizeStroke above)
        stroke.smoothedPoints = stroke.smoothedPoints.enumerated().map { index, point in
            var p = point
            // Feathered edges: slight width variation along the stroke
            let feather = sin(CGFloat(index) * 0.3) * 0.15
            p.pressure = max(0.2, min(0.8, p.pressure + feather))
            // Subtle flow variation (simulates water pooling)
            let flow = 1.0 + sin(CGFloat(index) * 0.15) * 0.1
            p.pressure *= flow
            return p
        }
    }
}
