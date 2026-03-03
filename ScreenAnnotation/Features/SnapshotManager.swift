import Cocoa

/// Captures annotated screen region and copies to clipboard.
class SnapshotManager {
    
    func captureScreen(completion: @escaping (NSImage?) -> Void) {
        capture(rect: nil, completion: completion)
    }
    
    func captureRegion(_ rect: CGRect, completion: @escaping (NSImage?) -> Void) {
        capture(rect: rect, completion: completion)
    }
    
    private func capture(rect: CGRect?, completion: @escaping (NSImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let displayID = CGMainDisplayID()
            let screenshot = rect.map { CGDisplayCreateImage(displayID, rect: $0) } ?? CGDisplayCreateImage(displayID)
            guard let screenshot else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let image = NSImage(cgImage: screenshot, size: NSSize(width: CGFloat(screenshot.width), height: CGFloat(screenshot.height)))
            DispatchQueue.main.async { completion(image) }
        }
    }
    
    /// Copies an image to the system clipboard.
    func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
    
    /// Captures and copies the full screen to clipboard.
    func snapshotToClipboard() {
        captureScreen { [weak self] image in
            guard let image = image else { return }
            self?.copyToClipboard(image)
        }
    }
    
    /// Captures and copies a region to clipboard.
    func snapshotRegionToClipboard(_ rect: CGRect) {
        captureRegion(rect) { [weak self] image in
            guard let image = image else { return }
            self?.copyToClipboard(image)
        }
    }
}
