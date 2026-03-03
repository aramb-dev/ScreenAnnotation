import Cocoa
import MetalKit

class CanvasView: NSView {
    
    let canvasManager: CanvasManager
    private var metalView: MTKView!
    private var renderer: MetalRenderer?
    private let inputManager = TabletInputManager()
    
    override init(frame frameRect: NSRect) {
        self.canvasManager = CanvasManager()
        super.init(frame: frameRect)
        setupMetal()
    }
    
    required init?(coder: NSCoder) {
        self.canvasManager = CanvasManager()
        super.init(coder: coder)
        setupMetal()
    }
    
    private func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("[ScreenAnnotation] Metal is not supported on this device")
            return
        }
        
        metalView = MTKView(frame: bounds, device: device)
        metalView.autoresizingMask = [.width, .height]
        metalView.layer?.isOpaque = false
        metalView.layer?.backgroundColor = CGColor.clear
        
        // Idle optimization: only redraw when we request it
        metalView.isPaused = true
        metalView.enableSetNeedsDisplay = true
        
        renderer = MetalRenderer(device: device, pixelFormat: metalView.colorPixelFormat)
        metalView.delegate = renderer
        renderer?.canvasManager = canvasManager
        
        addSubview(metalView)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        let options: NSTrackingArea.Options = [.activeAlways, .mouseMoved, .mouseEnteredAndExited]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }
    
    // MARK: - Hit Testing
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        // When drawing is disabled, pass all events through to apps underneath
        guard canvasManager.isDrawingEnabled else { return nil }
        
        // Convert the view-local point to screen coordinates
        guard let win = self.window else { return super.hitTest(point) }
        let windowPoint = self.convert(point, to: nil)
        let screenPoint = win.convertPoint(toScreen: windowPoint)
        
        // If any other visible window (e.g. toolbar) occupies this screen point,
        // let that window handle the event instead of the drawing overlay.
        for window in NSApp.windows where window !== self.window && window.isVisible {
            // Only defer to non-overlay windows (i.e. the toolbar panel)
            if window.frame.contains(screenPoint) && !window.ignoresMouseEvents {
                return nil
            }
        }
        
        return super.hitTest(point)
    }
    
    // MARK: - Mouse / Tablet Events
    
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let strokePoint = inputManager.processEvent(event, location: point)
        canvasManager.beginStroke(at: strokePoint)
        metalView.needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let strokePoint = inputManager.processEvent(event, location: point)
        canvasManager.continueStroke(to: strokePoint)
        metalView.needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let strokePoint = inputManager.processEvent(event, location: point)
        canvasManager.endStroke(at: strokePoint)
        metalView.needsDisplay = true
    }
    
    override func mouseMoved(with event: NSEvent) {
        // Update cursor position for laser pointer
        let point = convert(event.locationInWindow, from: nil)
        canvasManager.updateCursorPosition(point)
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
