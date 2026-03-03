import Cocoa

class LassoTool {
    
    private(set) var selectionPath: NSBezierPath?
    private(set) var selectedStrokeIndices: Set<Int> = []
    private var dragOrigin: CGPoint?
    
    var hasSelection: Bool { !selectedStrokeIndices.isEmpty }
    
    // MARK: - Selection
    
    func beginSelection(at point: CGPoint) {
        selectionPath = NSBezierPath()
        selectionPath?.move(to: point)
        selectedStrokeIndices = []
    }
    
    func continueSelection(to point: CGPoint) {
        selectionPath?.line(to: point)
    }
    
    func endSelection(in strokes: [Stroke]) {
        selectionPath?.close()
        guard let path = selectionPath else { return }
        
        selectedStrokeIndices = []
        for (index, stroke) in strokes.enumerated() {
            let isInside = stroke.activePoints.contains { path.contains($0.position) }
            if isInside {
                selectedStrokeIndices.insert(index)
            }
        }
    }
    
    // MARK: - Move
    
    func beginMove(at point: CGPoint) {
        dragOrigin = point
    }
    
    func continueMove(to point: CGPoint, strokes: inout [Stroke]) {
        guard let origin = dragOrigin else { return }
        let dx = point.x - origin.x
        let dy = point.y - origin.y
        
        for index in selectedStrokeIndices {
            guard index < strokes.count else { continue }
            strokes[index].translate(dx: dx, dy: dy)
        }
        
        dragOrigin = point
    }
    
    func endMove() {
        dragOrigin = nil
    }
    
    // MARK: - Actions
    
    func deleteSelected(from strokes: inout [Stroke]) {
        for index in selectedStrokeIndices.sorted(by: >) {
            guard index < strokes.count else { continue }
            strokes.remove(at: index)
        }
        clearSelection()
    }
    
    func duplicateSelected(from strokes: inout [Stroke]) -> [Stroke] {
        var duplicates: [Stroke] = []
        for index in selectedStrokeIndices {
            guard index < strokes.count else { continue }
            let original = strokes[index]
            let copy = Stroke(penType: original.penType, color: original.color, width: original.width, opacity: original.opacity)
            copy.points = original.points.map { p in
                StrokePoint(position: CGPoint(x: p.position.x + 20, y: p.position.y + 20),
                           pressure: p.pressure, tilt: p.tilt, rotation: p.rotation, timestamp: p.timestamp)
            }
            if !original.smoothedPoints.isEmpty {
                copy.smoothedPoints = StrokeSmoothing.smooth(points: copy.points)
            }
            duplicates.append(copy)
        }
        return duplicates
    }
    
    func clearSelection() {
        selectionPath = nil
        selectedStrokeIndices = []
        dragOrigin = nil
    }
}
