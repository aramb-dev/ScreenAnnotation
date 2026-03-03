import Cocoa

/// Handles tablet (Wacom, Apple Pencil via Sidecar) and mouse input,
/// extracting pressure, tilt, and rotation from NSEvent.
class TabletInputManager {
    
    func processEvent(_ event: NSEvent, location: CGPoint) -> StrokePoint {
        var pressure: CGFloat = 1.0
        var tilt: CGFloat = 0
        var rotation: CGFloat = 0
        
        switch event.type {
        case .tabletPoint, .leftMouseDown, .leftMouseDragged, .leftMouseUp:
            // Tablet devices provide pressure directly
            if event.subtype == .tabletPoint || event.subtype == .tabletProximity {
                pressure = CGFloat(event.pressure)
                tilt = CGFloat(event.tilt.x) // -1 to 1
                rotation = CGFloat(event.rotation)     // degrees
            } else {
                // Mouse: use force if available (Force Touch trackpad)
                pressure = extractForcePressure(from: event)
            }
            
        default:
            pressure = extractForcePressure(from: event)
        }
        
        // Clamp pressure
        pressure = max(0.01, min(1.0, pressure))
        
        return StrokePoint(
            position: location,
            pressure: pressure,
            tilt: tilt,
            rotation: rotation,
            timestamp: event.timestamp
        )
    }
    
    /// Extracts Force Touch pressure from trackpad events.
    private func extractForcePressure(from event: NSEvent) -> CGFloat {
        // NSEvent.pressure ranges from 0 to 1 for Force Touch
        let p = CGFloat(event.pressure)
        if p > 0 {
            return p
        }
        // Default pressure for regular mouse (full pressure for consistent stroke width)
        return 1.0
    }
}
