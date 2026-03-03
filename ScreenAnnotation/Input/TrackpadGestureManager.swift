import Cocoa

/// Manages Magic Trackpad gestures (Force Touch pressure, two-finger rotate for ruler).
class TrackpadGestureManager {
    
    var onRotate: ((CGFloat) -> Void)?
    var onMagnify: ((CGFloat) -> Void)?
    
    func handleRotation(_ event: NSEvent) {
        // Two-finger rotation for ruler tool
        let rotation = event.rotation * (.pi / 180.0) // Convert degrees to radians
        onRotate?(CGFloat(rotation))
    }
    
    func handleMagnification(_ event: NSEvent) {
        onMagnify?(event.magnification)
    }
    
    /// Extracts pressure from Force Touch trackpad.
    func forcePressure(from event: NSEvent) -> CGFloat {
        // Stage 1: light press (0-0.5), Stage 2: deep press (0.5-1.0)
        return max(0.01, min(1.0, CGFloat(event.pressure)))
    }
}
