import Cocoa

enum EraserMode {
    case pixel
    case object
}

class EraserTool {
    var mode: EraserMode = .object
    var eraserRadius: CGFloat = 10.0
    
    func toggleMode() {
        mode = (mode == .pixel) ? .object : .pixel
    }
    
    /// Object eraser: returns the index of the stroke that was hit, or nil.
    func hitTestStroke(at point: CGPoint, in strokes: [Stroke]) -> Int? {
        for (index, stroke) in strokes.enumerated().reversed() {
            for sp in stroke.activePoints {
                let distance = hypot(point.x - sp.position.x, point.y - sp.position.y)
                if distance <= stroke.width + eraserRadius {
                    return index
                }
            }
        }
        return nil
    }
    
    /// Pixel eraser: splits a stroke at the erased point, returning the remaining segments.
    func pixelErase(at point: CGPoint, radius: CGFloat, stroke: Stroke) -> [Stroke] {
        var segments: [[StrokePoint]] = []
        var currentSegment: [StrokePoint] = []
        
        for sp in stroke.activePoints {
            let distance = hypot(point.x - sp.position.x, point.y - sp.position.y)
            if distance > radius + stroke.width {
                currentSegment.append(sp)
            } else {
                if currentSegment.count >= 2 {
                    segments.append(currentSegment)
                }
                currentSegment = []
            }
        }
        
        if currentSegment.count >= 2 {
            segments.append(currentSegment)
        }
        
        return segments.map { points in
            let newStroke = Stroke(penType: stroke.penType, color: stroke.color, width: stroke.width, opacity: stroke.opacity)
            newStroke.points = points
            if points.count >= 4 {
                newStroke.smoothedPoints = StrokeSmoothing.smooth(points: points)
            }
            return newStroke
        }
    }
}
