import SwiftUI

/// Toolbar panel controller — hosts the SwiftUI FloatingToolbar in a separate NSPanel.
class ToolbarPanelController {
    
    let panel: NSPanel
    weak var canvasManager: CanvasManager?
    
    init(canvasManager: CanvasManager?) {
        self.canvasManager = canvasManager
        
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        // Give the toolbar plenty of vertical room so the capsule + shadow never clip.
        // The SwiftUI content is ~44pt tall; 80pt gives comfortable headroom.
        let panelWidth: CGFloat = 900
        let panelHeight: CGFloat = 80
        let origin = NSPoint(
            x: screenFrame.midX - panelWidth / 2,
            y: screenFrame.maxY - panelHeight - 10
        )
        
        panel = NSPanel(
            contentRect: NSRect(origin: origin, size: NSSize(width: panelWidth, height: panelHeight)),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 2)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        
        if let manager = canvasManager {
            let toolbarView = FloatingToolbar(canvasManager: manager)
            let hostingView = NSHostingView(rootView: toolbarView)
            hostingView.frame = NSRect(origin: .zero, size: NSSize(width: panelWidth, height: panelHeight))
            // Prevent AppKit from clipping SwiftUI content at the view boundary
            hostingView.wantsLayer = true
            hostingView.layer?.masksToBounds = false
            panel.contentView = hostingView
        }
    }
    
    func showToolbar() {
        panel.orderFrontRegardless()
    }
    
    func hideToolbar() {
        panel.orderOut(nil)
    }
    
    func toggleVisibility() {
        if panel.isVisible {
            hideToolbar()
        } else {
            showToolbar()
        }
    }
}
