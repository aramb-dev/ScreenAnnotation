import Cocoa

enum RecognizedShapeType {
    case line
    case arrow
    case circle
    case ellipse
    case rectangle
    case triangle
    case star
    case heart
    case cloud
    case speechBubble
}

class ShapeRecognizer {
    
    /// Minimum dwell time at the end of a stroke to trigger shape recognition (300ms).
    private let dwellThreshold: TimeInterval = 0.3
    
    /// Minimum number of points to attempt recognition.
    private let minimumPoints = 10
    
    /// Attempts to recognize a shape from the stroke. Returns a clean NSBezierPath if recognized.
    func recognize(stroke: Stroke) -> NSBezierPath? {
        let points = stroke.points
        guard points.count >= minimumPoints else { return nil }
        
        // Check for dwell at end of stroke (pause-to-snap)
        guard detectDwell(in: points) else { return nil }
        
        let positions = points.map { $0.position }
        
        // Try recognition in order of specificity
        if let arrow = recognizeArrow(positions) { return arrow }
        if let line = recognizeLine(positions) { return line }
        if let circle = recognizeCircle(positions) { return circle }
        if let rectangle = recognizeRectangle(positions) { return rectangle }
        if let triangle = recognizeTriangle(positions) { return triangle }
        
        return nil
    }
    
    // MARK: - Dwell Detection
    
    private func detectDwell(in points: [StrokePoint]) -> Bool {
        guard points.count >= 3 else { return false }
        let last = points.last!
        let count = min(5, points.count)
        let recent = points.suffix(count)
        
        // Check if the last few points were nearly stationary
        let maxMovement: CGFloat = 5.0
        for point in recent {
            let dist = hypot(point.position.x - last.position.x, point.position.y - last.position.y)
            if dist > maxMovement { return false }
        }
        
        // Check time dwell
        let firstRecent = recent.first!
        let dwellTime = last.timestamp - firstRecent.timestamp
        return dwellTime >= dwellThreshold
    }
    
    // MARK: - Line Recognition
    
    private func recognizeLine(_ points: [CGPoint]) -> NSBezierPath? {
        guard points.count >= 2 else { return nil }
        let start = points.first!
        let end = points.last!
        
        let lineLength = hypot(end.x - start.x, end.y - start.y)
        guard lineLength > 30 else { return nil }
        
        // Check if all points are close to the line from start to end
        var maxDeviation: CGFloat = 0
        for point in points {
            let deviation = distanceToLine(point: point, lineStart: start, lineEnd: end)
            maxDeviation = max(maxDeviation, deviation)
        }
        
        let threshold = lineLength * 0.08
        guard maxDeviation < threshold else { return nil }
        
        let path = NSBezierPath()
        path.move(to: start)
        path.line(to: end)
        return path
    }
    
    // MARK: - Arrow Recognition
    
    private func recognizeArrow(_ points: [CGPoint]) -> NSBezierPath? {
        guard points.count >= 10 else { return nil }
        
        // An arrow has a main shaft and a v-shaped head
        // Simple heuristic: check if the stroke doubles back near the end
        let start = points.first!
        let end = points.last!
        let lineLength = hypot(end.x - start.x, end.y - start.y)
        guard lineLength > 40 else { return nil }
        
        // Check for direction reversal in the last 30% of points (arrowhead)
        let headStart = Int(Double(points.count) * 0.7)
        let headPoints = Array(points[headStart...])
        guard headPoints.count >= 3 else { return nil }
        
        // Check if the head points deviate significantly from the main line
        let mainDirection = CGPoint(x: end.x - start.x, y: end.y - start.y)
        let mainAngle = atan2(mainDirection.y, mainDirection.x)
        
        var hasDeviation = false
        for point in headPoints {
            let deviation = distanceToLine(point: point, lineStart: start, lineEnd: points[headStart])
            if deviation > lineLength * 0.1 {
                hasDeviation = true
                break
            }
        }
        
        guard hasDeviation else { return nil }
        
        // Build arrow path
        let tipPoint = points[headStart]
        let arrowLength: CGFloat = 15
        let arrowAngle: CGFloat = .pi / 6
        
        let path = NSBezierPath()
        path.move(to: start)
        path.line(to: tipPoint)
        
        // Arrowhead
        let leftPoint = CGPoint(
            x: tipPoint.x - arrowLength * cos(mainAngle - arrowAngle),
            y: tipPoint.y - arrowLength * sin(mainAngle - arrowAngle)
        )
        let rightPoint = CGPoint(
            x: tipPoint.x - arrowLength * cos(mainAngle + arrowAngle),
            y: tipPoint.y - arrowLength * sin(mainAngle + arrowAngle)
        )
        
        path.move(to: tipPoint)
        path.line(to: leftPoint)
        path.move(to: tipPoint)
        path.line(to: rightPoint)
        
        return path
    }
    
    // MARK: - Circle Recognition
    
    private func recognizeCircle(_ points: [CGPoint]) -> NSBezierPath? {
        guard points.count >= 8 else { return nil }
        
        let closureDistance = hypot(points.last!.x - points.first!.x, points.last!.y - points.first!.y)
        
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        let center = CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
        
        // Calculate mean radius
        let radii = points.map { hypot($0.x - center.x, $0.y - center.y) }
        let meanRadius = radii.reduce(0, +) / CGFloat(radii.count)
        
        guard meanRadius > 10 else { return nil }
        guard closureDistance < meanRadius * 0.5 else { return nil }
        
        // Check circularity: variance of radii should be small
        let variance = radii.map { ($0 - meanRadius) * ($0 - meanRadius) }.reduce(0, +) / CGFloat(radii.count)
        let stdDev = sqrt(variance)
        let circularityRatio = stdDev / meanRadius
        
        guard circularityRatio < 0.15 else { return nil }
        
        let rect = CGRect(
            x: center.x - meanRadius,
            y: center.y - meanRadius,
            width: meanRadius * 2,
            height: meanRadius * 2
        )
        
        return NSBezierPath(ovalIn: rect)
    }
    
    // MARK: - Rectangle Recognition
    
    private func recognizeRectangle(_ points: [CGPoint]) -> NSBezierPath? {
        guard points.count >= 8 else { return nil }
        
        let closureDistance = hypot(points.last!.x - points.first!.x, points.last!.y - points.first!.y)
        let (minX, maxX, minY, maxY) = boundingBox(of: points)
        
        let width = maxX - minX
        let height = maxY - minY
        
        guard width > 20 && height > 20 else { return nil }
        guard closureDistance < max(width, height) * 0.3 else { return nil }
        
        // Check if points cluster near the bounding box edges
        let edgeThreshold = max(width, height) * 0.12
        var nearEdge = 0
        for point in points {
            let distToLeft = abs(point.x - minX)
            let distToRight = abs(point.x - maxX)
            let distToTop = abs(point.y - maxY)
            let distToBottom = abs(point.y - minY)
            let minDist = min(distToLeft, distToRight, distToTop, distToBottom)
            if minDist < edgeThreshold {
                nearEdge += 1
            }
        }
        
        let edgeRatio = CGFloat(nearEdge) / CGFloat(points.count)
        guard edgeRatio > 0.7 else { return nil }
        
        // Detect corners (approximately 4 direction changes)
        let corners = detectCorners(in: points)
        guard corners.count >= 3 && corners.count <= 6 else { return nil }
        
        let rect = CGRect(x: minX, y: minY, width: width, height: height)
        return NSBezierPath(rect: rect)
    }
    
    // MARK: - Triangle Recognition
    
    private func recognizeTriangle(_ points: [CGPoint]) -> NSBezierPath? {
        guard points.count >= 6 else { return nil }
        
        let closureDistance = hypot(points.last!.x - points.first!.x, points.last!.y - points.first!.y)
        let (minX, maxX, minY, maxY) = boundingBox(of: points)
        let diagonal = hypot(maxX - minX, maxY - minY)
        
        guard closureDistance < diagonal * 0.3 else { return nil }
        
        let corners = detectCorners(in: points)
        guard corners.count == 3 else { return nil }
        
        let path = NSBezierPath()
        path.move(to: corners[0])
        path.line(to: corners[1])
        path.line(to: corners[2])
        path.close()
        return path
    }
    
    // MARK: - Helpers
    
    private func boundingBox(of points: [CGPoint]) -> (minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat) {
        var minX = CGFloat.infinity, maxX = -CGFloat.infinity
        var minY = CGFloat.infinity, maxY = -CGFloat.infinity
        for p in points {
            if p.x < minX { minX = p.x }; if p.x > maxX { maxX = p.x }
            if p.y < minY { minY = p.y }; if p.y > maxY { maxY = p.y }
        }
        return (minX, maxX, minY, maxY)
    }
    
    private func distanceToLine(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        let lengthSq = dx * dx + dy * dy
        guard lengthSq > 0 else { return hypot(point.x - lineStart.x, point.y - lineStart.y) }
        
        var t = ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / lengthSq
        t = max(0, min(1, t))
        
        let projX = lineStart.x + t * dx
        let projY = lineStart.y + t * dy
        return hypot(point.x - projX, point.y - projY)
    }
    
    private func detectCorners(in points: [CGPoint], angleTolerance: CGFloat = .pi / 4) -> [CGPoint] {
        guard points.count >= 6 else { return [] }
        
        var corners: [CGPoint] = []
        let step = max(1, points.count / 20)
        
        for i in stride(from: step, to: points.count - step, by: step) {
            let prev = points[i - step]
            let curr = points[i]
            let next = points[min(i + step, points.count - 1)]
            
            let angle1 = atan2(curr.y - prev.y, curr.x - prev.x)
            let angle2 = atan2(next.y - curr.y, next.x - curr.x)
            var angleDiff = abs(angle2 - angle1)
            if angleDiff > .pi { angleDiff = 2 * .pi - angleDiff }
            
            if angleDiff > angleTolerance {
                // Avoid adding corners too close together
                if let last = corners.last {
                    let dist = hypot(curr.x - last.x, curr.y - last.y)
                    if dist < 20 { continue }
                }
                corners.append(curr)
            }
        }
        
        return corners
    }
}
