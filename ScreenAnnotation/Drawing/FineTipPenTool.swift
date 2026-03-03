import Cocoa

/// Fine Tip Pen Tool — very thin, consistent line weight; "Virtual Sharpie".
struct FineTipPenTool: DrawingTool {
    let penType: PenType = .fineTip
    var displayName: String { "Fine Tip Pen" }
    
    func createStroke(color: NSColor, width: CGFloat) -> Stroke {
        return Stroke(penType: .fineTip, color: color, width: max(width, 1.0), opacity: 1.0)
    }
    
    func processPoint(_ point: StrokePoint, in stroke: Stroke) -> StrokePoint {
        // Normalize pressure to near-constant for uniform width
        var modified = point
        modified.pressure = 0.5
        return modified
    }
}
