import Cocoa
import MetalKit

class OverlayPanelController {
    
    let panel: AnnotationPanel
    let canvasManager: CanvasManager?
    private let canvasView: CanvasView
    private var cursorHidden = false
    
    init(screen: NSScreen) {
        let screenFrame = screen.frame
        
        panel = AnnotationPanel(
            contentRect: screenFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // Always-on-top: screenSaverWindow + 1 ensures Zoom/Teams/OBS capture it
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
        panel.isOpaque = false
        panel.backgroundColor = NSColor.clear
        panel.hasShadow = false
        // Start in passthrough mode — clicks go through to apps underneath
        panel.ignoresMouseEvents = true
        panel.acceptsMouseMovedEvents = true
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        // Allows the panel to receive key/mouse events without activating (stealing focus)
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        
        canvasView = CanvasView(frame: screenFrame)
        canvasManager = canvasView.canvasManager
        panel.contentView = canvasView
    }
    
    func showOverlay() {
        panel.orderFrontRegardless()
    }
    
    func hideOverlay() {
        panel.orderOut(nil)
    }
    
    func toggleVisibility() {
        if panel.isVisible {
            hideOverlay()
        } else {
            showOverlay()
        }
    }
    
    func toggleCursorVisibility() {
        cursorHidden.toggle()
        if cursorHidden {
            NSCursor.hide()
        } else {
            NSCursor.unhide()
        }
    }
    
    /// Enables or disables drawing mode. When disabled, clicks pass through to underlying apps.
    func setDrawingEnabled(_ enabled: Bool) {
        panel.ignoresMouseEvents = !enabled
        canvasManager?.isDrawingEnabled = enabled
        if enabled {
            if canvasManager?.activeTool == ActiveTool.none {
                canvasManager?.activeTool = .drawing(.pen)
            }
        }
    }
}

// MARK: - Custom NSPanel that can become key without becoming main

class AnnotationPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
