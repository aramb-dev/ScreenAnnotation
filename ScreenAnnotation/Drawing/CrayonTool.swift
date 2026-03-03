import Cocoa

/// Crayon Tool — waxy, grainy texture; slightly rough edges; rich, vibrant color.
struct CrayonTool: DrawingTool {
    let penType: PenType = .crayon
    var displayName: String { "Crayon" }
    
    func createStroke(color: NSColor, width: CGFloat) -> Stroke {
        // Crayons tend to be wider with vibrant/saturated colors
        return Stroke(penType: .crayon, color: saturateColor(color), width: max(width, 5.0), opacity: 0.85)
    }
    
    func processPoint(_ point: StrokePoint, in stroke: Stroke) -> StrokePoint {
        return point
    }
    
    func finalizeStroke(_ stroke: Stroke) {
        stroke.smoothedPoints = stroke.points.count >= 4
            ? StrokeSmoothing.smooth(points: stroke.points, subdivisions: 3)
            : stroke.points
        applyWaxyTexture(to: stroke)
    }
    
    private func applyWaxyTexture(to stroke: Stroke) {
        // Operate on smoothedPoints directly (always populated by finalizeStroke above)
        stroke.smoothedPoints = stroke.smoothedPoints.enumerated().map { index, point in
            var p = point
            // Waxy grain: periodic pressure variation + random jitter
            let waxGrain = sin(CGFloat(index) * 0.8) * 0.1 + CGFloat.random(in: -0.2...0.2)
            p.pressure = max(0.3, min(1.0, p.pressure + waxGrain))
            // Slightly rough edges: tiny position jitter
            let jitter = CGFloat.random(in: -0.5...0.5)
            p.position.x += jitter
            p.position.y += jitter
            return p
        }
    }
    
    private func saturateColor(_ color: NSColor) -> NSColor {
        guard let hsbColor = color.usingColorSpace(.deviceRGB) else { return color }
        return NSColor(
            hue: hsbColor.hueComponent,
            saturation: min(1.0, hsbColor.saturationComponent * 1.3),
            brightness: hsbColor.brightnessComponent,
            alpha: hsbColor.alphaComponent
        )
    }
}
