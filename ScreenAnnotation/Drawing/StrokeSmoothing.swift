import Foundation
import CoreGraphics

struct StrokeSmoothing {
    
    /// Applies Catmull-Rom spline interpolation to the stroke points.
    /// Catmull-Rom passes through all control points (unlike Bézier which approximates).
    static func smooth(points: [StrokePoint], subdivisions: Int = 4) -> [StrokePoint] {
        guard points.count >= 4 else { return points }
        
        var smoothed: [StrokePoint] = []
        
        for i in 0..<(points.count - 1) {
            let p0 = points[max(0, i - 1)]
            let p1 = points[i]
            let p2 = points[min(points.count - 1, i + 1)]
            let p3 = points[min(points.count - 1, i + 2)]
            
            for j in 0..<subdivisions {
                let t = CGFloat(j) / CGFloat(subdivisions)
                let interpolated = catmullRomInterpolate(p0: p0, p1: p1, p2: p2, p3: p3, t: t)
                smoothed.append(interpolated)
            }
        }
        
        // Add the last point
        if let last = points.last {
            smoothed.append(last)
        }
        
        return smoothed
    }
    
    /// Catmull-Rom interpolation between p1 and p2, using p0 and p3 as tangent guides.
    private static func catmullRomInterpolate(
        p0: StrokePoint, p1: StrokePoint, p2: StrokePoint, p3: StrokePoint, t: CGFloat
    ) -> StrokePoint {
        let t2 = t * t
        let t3 = t2 * t
        
        // Catmull-Rom matrix coefficients
        let x = 0.5 * ((2.0 * p1.position.x) +
                        (-p0.position.x + p2.position.x) * t +
                        (2.0 * p0.position.x - 5.0 * p1.position.x + 4.0 * p2.position.x - p3.position.x) * t2 +
                        (-p0.position.x + 3.0 * p1.position.x - 3.0 * p2.position.x + p3.position.x) * t3)
        
        let y = 0.5 * ((2.0 * p1.position.y) +
                        (-p0.position.y + p2.position.y) * t +
                        (2.0 * p0.position.y - 5.0 * p1.position.y + 4.0 * p2.position.y - p3.position.y) * t2 +
                        (-p0.position.y + 3.0 * p1.position.y - 3.0 * p2.position.y + p3.position.y) * t3)
        
        // Linearly interpolate pressure, tilt, rotation
        let pressure = lerp(p1.pressure, p2.pressure, t: t)
        let tilt = lerp(p1.tilt, p2.tilt, t: t)
        let rotation = lerp(p1.rotation, p2.rotation, t: t)
        let timestamp = lerp(p1.timestamp, p2.timestamp, t: Double(t))
        
        return StrokePoint(
            position: CGPoint(x: x, y: y),
            pressure: pressure,
            tilt: tilt,
            rotation: rotation,
            timestamp: timestamp
        )
    }
    
    private static func lerp(_ a: CGFloat, _ b: CGFloat, t: CGFloat) -> CGFloat {
        return a + (b - a) * t
    }
    
    private static func lerp(_ a: Double, _ b: Double, t: Double) -> Double {
        return a + (b - a) * t
    }
}
