import Cocoa

/// Protocol that all drawing tools conform to.
protocol DrawingTool {
    var penType: PenType { get }
    var displayName: String { get }
    
    /// Creates a new stroke with the tool's default settings.
    func createStroke(color: NSColor, width: CGFloat) -> Stroke
    
    /// Processes a raw input point through the tool's pressure/angle mapping.
    func processPoint(_ point: StrokePoint, in stroke: Stroke) -> StrokePoint
    
    /// Called when stroke is finished; apply final processing (e.g., smoothing, texture).
    func finalizeStroke(_ stroke: Stroke)
}

extension DrawingTool {
    func processPoint(_ point: StrokePoint, in stroke: Stroke) -> StrokePoint {
        return point
    }
    
    func finalizeStroke(_ stroke: Stroke) {
        if stroke.points.count >= 4 {
            stroke.smoothedPoints = StrokeSmoothing.smooth(points: stroke.points)
        }
    }
}
