import Cocoa
import Combine

enum ActiveTool: Equatable {
    case drawing(PenType)
    case eraser
    case lasso
    case ruler
    case text
    case shape
    case none
}

class CanvasManager: ObservableObject {
    
    // MARK: - Published State
    @Published var activeTool: ActiveTool = .none
    @Published var currentColor: NSColor = .red
    @Published var currentWidth: CGFloat = 3.0
    @Published var currentOpacity: CGFloat = 1.0
    @Published var isDrawingEnabled: Bool = false
    @Published var selectedShapeType: RecognizedShapeType = .rectangle
    
    // MARK: - Strokes
    private(set) var strokes: [Stroke] = []
    private var currentStroke: Stroke?
    private var undoStack: [[Stroke]] = []
    private var redoStack: [[Stroke]] = []
    
    // MARK: - Tools
    private let drawingTools: [PenType: any DrawingTool] = [
        .pen: PenTool(),
        .fineTip: FineTipPenTool(),
        .highlighter: HighlighterTool(),
        .pencil: PencilTool(),
        .crayon: CrayonTool(),
        .calligraphy: CalligraphyTool(),
        .watercolor: WatercolorTool(),
        .laserPointer: LaserPointerTool(),
    ]
    
    let eraserTool = EraserTool()
    let lassoTool = LassoTool()
    let rulerTool = RulerTool()
    let shapeRecognizer = ShapeRecognizer()
    
    // MARK: - Laser Pointer Timer
    private var laserFadeTimers: [UUID: Timer] = [:]
    private var onNeedsDisplay: (() -> Void)?
    
    var allStrokes: [Stroke] {
        var result = strokes
        if let current = currentStroke {
            result.append(current)
        }
        return result
    }
    
    func setNeedsDisplayCallback(_ callback: @escaping () -> Void) {
        onNeedsDisplay = callback
    }
    
    // MARK: - Tool Selection
    
    func selectPen(_ penType: PenType) {
        activeTool = .drawing(penType)
    }
    
    func selectEraser() {
        activeTool = .eraser
    }
    
    func selectLasso() {
        activeTool = .lasso
    }
    
    func selectRuler() {
        activeTool = .ruler
        rulerTool.toggle()
    }
    
    func toggleEraser() {
        if activeTool == .eraser {
            activeTool = .drawing(.pen)
        } else {
            activeTool = .eraser
        }
    }
    
    private var toolBeforeDisable: ActiveTool = .drawing(.pen)
    
    func toggleDrawing() {
        isDrawingEnabled.toggle()
        if isDrawingEnabled {
            activeTool = toolBeforeDisable
        } else {
            toolBeforeDisable = (activeTool == .none) ? .drawing(.pen) : activeTool
            activeTool = .none
        }
    }
    
    // MARK: - Drawing
    
    func beginStroke(at point: StrokePoint) {
        switch activeTool {
        case .drawing(let penType):
            guard let tool = drawingTools[penType] else { return }
            saveUndoState()
            let stroke = tool.createStroke(color: currentColor, width: currentWidth)
            let processed = tool.processPoint(point, in: stroke)
            stroke.addPoint(processed)
            currentStroke = stroke
            
        case .eraser:
            handleErase(at: point.position)
            
        case .lasso:
            if lassoTool.hasSelection {
                lassoTool.beginMove(at: point.position)
            } else {
                lassoTool.beginSelection(at: point.position)
            }
            
        case .ruler:
            break
            
        default:
            break
        }
    }
    
    func continueStroke(to point: StrokePoint) {
        switch activeTool {
        case .drawing(let penType):
            guard let stroke = currentStroke, let tool = drawingTools[penType] else { return }
            var processedPoint = tool.processPoint(point, in: stroke)
            
            // If ruler is visible and close, constrain to ruler edge
            if rulerTool.isVisible && rulerTool.distanceToRuler(from: point.position) < 40 {
                processedPoint.position = rulerTool.constrainPoint(point.position)
            }
            
            stroke.addPoint(processedPoint)
            
            // Real-time smoothing for display
            if stroke.points.count >= 4 {
                stroke.smoothedPoints = StrokeSmoothing.smooth(points: stroke.points)
            }
            
        case .eraser:
            handleErase(at: point.position)
            
        case .lasso:
            if lassoTool.hasSelection {
                lassoTool.continueMove(to: point.position, strokes: &strokes)
            } else {
                lassoTool.continueSelection(to: point.position)
            }
            
        default:
            break
        }
    }
    
    func endStroke(at point: StrokePoint) {
        switch activeTool {
        case .drawing(let penType):
            guard let stroke = currentStroke, let tool = drawingTools[penType] else { return }
            tool.finalizeStroke(stroke)
            
            // Shape recognition: detect pause-to-snap
            if penType != .laserPointer {
                if let recognized = shapeRecognizer.recognize(stroke: stroke) {
                    stroke.isRecognizedShape = true
                    stroke.recognizedShapePath = recognized
                }
            }
            
            strokes.append(stroke)
            currentStroke = nil
            
            // Start fade timer for laser pointer strokes
            if penType == .laserPointer {
                startLaserFade(for: stroke)
            }
            
        case .lasso:
            if lassoTool.hasSelection {
                lassoTool.endMove()
            } else {
                lassoTool.endSelection(in: strokes)
            }
            
        default:
            break
        }
    }
    
    func updateCursorPosition(_ point: CGPoint) {}
    
    // MARK: - Eraser
    
    private func handleErase(at point: CGPoint) {
        switch eraserTool.mode {
        case .object:
            if let index = eraserTool.hitTestStroke(at: point, in: strokes) {
                saveUndoState()
                strokes.remove(at: index)
            }
        case .pixel:
            var didChange = false
            var i = strokes.count - 1
            while i >= 0 {
                let remaining = eraserTool.pixelErase(at: point, radius: eraserTool.eraserRadius, stroke: strokes[i])
                if remaining.count != 1 || remaining.first?.id != strokes[i].id {
                    if !didChange {
                        saveUndoState()
                        didChange = true
                    }
                    strokes.remove(at: i)
                    for (j, segment) in remaining.enumerated() {
                        strokes.insert(segment, at: i + j)
                    }
                    // No index adjustment needed — we iterate backwards and the
                    // inserted segments sit at i..i+remaining.count-1, which we skip
                    // by simply decrementing i below.
                }
                i -= 1
            }
        }
    }
    
    // MARK: - Laser Pointer Fade
    
    private func startLaserFade(for stroke: Stroke) {
        let fadeStart = ProcessInfo.processInfo.systemUptime
        let duration = LaserPointerTool.fadeDuration
        let strokeId = stroke.id

        laserFadeTimers[strokeId]?.invalidate()
        laserFadeTimers[strokeId] = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            let elapsed = ProcessInfo.processInfo.systemUptime - fadeStart
            let progress = min(1.0, elapsed / duration)
            stroke.fadeAlpha = 1.0 - progress
            stroke.opacity = 1.0 - progress

            self?.onNeedsDisplay?()

            if progress >= 1.0 {
                timer.invalidate()
                self?.laserFadeTimers.removeValue(forKey: strokeId)
                self?.strokes.removeAll { $0.id == strokeId }
                self?.onNeedsDisplay?()
            }
        }
    }
    
    // MARK: - Undo / Redo
    
    private func saveUndoState() {
        undoStack.append(strokes)
        redoStack.removeAll()
        // Limit undo history
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }
    }
    
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    
    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(strokes)
        strokes = previous
    }
    
    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(strokes)
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }
        strokes = next
    }
    
    func clearAll() {
        saveUndoState()
        strokes.removeAll()
        currentStroke = nil
        lassoTool.clearSelection()
    }
    
    // MARK: - Lasso Actions
    
    func deleteSelectedStrokes() {
        saveUndoState()
        lassoTool.deleteSelected(from: &strokes)
    }
    
    func duplicateSelectedStrokes() {
        saveUndoState()
        let duplicates = lassoTool.duplicateSelected(from: &strokes)
        strokes.append(contentsOf: duplicates)
    }
}
