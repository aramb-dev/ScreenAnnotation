import Cocoa

/// Pencil Tool — graphite feel; thin textured line with subtle shading variations.
struct PencilTool: DrawingTool {
    let penType: PenType = .pencil
    var displayName: String { "Pencil" }
    
    func createStroke(color: NSColor, width: CGFloat) -> Stroke {
        return Stroke(penType: .pencil, color: color, width: width, opacity: 0.8)
    }
    
    func processPoint(_ point: StrokePoint, in stroke: Stroke) -> StrokePoint {
        var modified = point
        // Use tilt to modulate shading: more tilt = wider/lighter shading
        let tiltFactor = max(0.3, 1.0 - point.tilt * 0.5)
        modified.pressure = point.pressure * tiltFactor
        return modified
    }
    
    func finalizeStroke(_ stroke: Stroke) {
        // Apply smoothing with fewer subdivisions for a more natural pencil feel
        stroke.smoothedPoints = stroke.points.count >= 4
            ? StrokeSmoothing.smooth(points: stroke.points, subdivisions: 3)
            : stroke.points
        // Add subtle randomness to simulate graphite grain on top of smoothed points
        applyGrainEffect(to: stroke)
    }
    
    private func applyGrainEffect(to stroke: Stroke) {
        // Operate on smoothedPoints directly (always populated by finalizeStroke above)
        stroke.smoothedPoints = stroke.smoothedPoints.map { point in
            var p = point
            // Small random pressure variation for grain texture feel
            let grain = CGFloat.random(in: -0.3...0.3)
            p.pressure = max(0.1, min(1.0, p.pressure + grain * 0.15))
            return p
        }
    }
}
