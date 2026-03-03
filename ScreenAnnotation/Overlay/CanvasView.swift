import Cocoa
import Combine
import MetalKit

class CanvasView: NSView {

    let canvasManager: CanvasManager
    private var metalView: MTKView!
    private var renderer: MetalRenderer?
    private let inputManager = TabletInputManager()
    private var overlayView: AnnotationOverlayView!
    private var textEditorView: TextEditorView!
    private var cancellables = Set<AnyCancellable>()

    override init(frame frameRect: NSRect) {
        self.canvasManager = CanvasManager()
        super.init(frame: frameRect)
        setupMetal()
        setupOverlay()
        setupTextEditor()
        observeTextEditor()
    }

    required init?(coder: NSCoder) {
        self.canvasManager = CanvasManager()
        super.init(coder: coder)
        setupMetal()
        setupOverlay()
        setupTextEditor()
        observeTextEditor()
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

    private func setupOverlay() {
        overlayView = AnnotationOverlayView(frame: bounds)
        overlayView.autoresizingMask = [.width, .height]
        overlayView.canvasManager = canvasManager
        addSubview(overlayView)
    }

    private func setupTextEditor() {
        textEditorView = TextEditorView(frame: .zero)
        textEditorView.isHidden = true
        textEditorView.onCommit = { [weak self] text in
            guard let self else { return }
            self.canvasManager.activeTextEditor = nil
            self.requestRedraw()
        }
        addSubview(textEditorView)
    }

    private func observeTextEditor() {
        canvasManager.$activeTextEditor
            .receive(on: RunLoop.main)
            .sink { [weak self] annotation in
                guard let self else { return }
                if let annotation {
                    self.textEditorView.startEditing(annotation: annotation)
                } else {
                    if !self.textEditorView.isHidden {
                        self.textEditorView.commitEditing()
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func requestRedraw() {
        metalView?.needsDisplay = true
        overlayView?.needsDisplay = true
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
        requestRedraw()
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let strokePoint = inputManager.processEvent(event, location: point)
        canvasManager.continueStroke(to: strokePoint)
        requestRedraw()
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let strokePoint = inputManager.processEvent(event, location: point)
        canvasManager.endStroke(at: strokePoint)
        requestRedraw()
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        canvasManager.updateCursorPosition(point)
    }

    // MARK: - Keyboard Events

    override func keyDown(with event: NSEvent) {
        let key = event.charactersIgnoringModifiers ?? ""
        let modifiers = event.modifierFlags

        // Delete / Backspace — delete selected strokes
        if event.keyCode == 51 || event.keyCode == 117 {
            canvasManager.deleteSelectedStrokes()
            requestRedraw()
            return
        }

        // Cmd+D — duplicate selected strokes
        if modifiers.contains(.command) && key == "d" {
            canvasManager.duplicateSelectedStrokes()
            requestRedraw()
            return
        }

        super.keyDown(with: event)
    }

    // MARK: - Scroll Wheel (ruler rotation)

    override func scrollWheel(with event: NSEvent) {
        if canvasManager.rulerTool.isVisible {
            let delta = event.scrollingDeltaY * 0.005
            canvasManager.rulerTool.rotate(by: delta)
            requestRedraw()
            return
        }
        super.scrollWheel(with: event)
    }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
