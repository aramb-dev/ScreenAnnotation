import Cocoa

/// Transparent NSView layered on top of MTKView for CoreGraphics rendering.
/// Renders shapes, text, ruler, lasso selection path, and signature images.
class AnnotationOverlayView: NSView {

  weak var canvasManager: CanvasManager?

  override var isOpaque: Bool { false }

  override func hitTest(_ point: NSPoint) -> NSView? {
    // Always pass events through — CanvasView handles input
    return nil
  }

  override func draw(_ dirtyRect: NSRect) {
    guard let context = NSGraphicsContext.current?.cgContext,
          let cm = canvasManager else { return }

    // --- Shapes ---
    for shape in cm.shapeAnnotations {
      ShapeRenderer.render(shape, in: context)
    }
    if let preview = cm.currentShapePreview {
      ShapeRenderer.render(preview, in: context)
    }
    if let selected = cm.selectedShape {
      ShapeRenderer.renderHandles(selected, in: context)
    }

    // --- Text ---
    for annotation in cm.textAnnotations {
      guard !annotation.text.isEmpty else { continue }
      annotation.render(in: context)
    }

    // --- Signatures ---
    for sig in cm.signatureAnnotations {
      sig.image.draw(in: sig.frame)
    }

    // --- Ruler ---
    if cm.rulerTool.isVisible {
      drawRuler(cm.rulerTool, in: context)
    }

    // --- Lasso selection path ---
    if let path = cm.lassoTool.selectionPath {
      drawLassoPath(path, in: context)
    }
  }

  // MARK: - Ruler Drawing

  private func drawRuler(_ ruler: RulerTool, in context: CGContext) {
    let barWidth: CGFloat = 40
    let halfBar = barWidth / 2

    context.saveGState()

    // Translate to ruler center, rotate
    context.translateBy(x: ruler.position.x, y: ruler.position.y)
    context.rotate(by: ruler.angle)

    let halfLength = ruler.length / 2
    let barRect = CGRect(x: -halfLength, y: -halfBar, width: ruler.length, height: barWidth)

    // Translucent fill
    context.setFillColor(NSColor.systemBlue.withAlphaComponent(0.12).cgColor)
    context.fill(barRect)

    // Edge lines
    context.setStrokeColor(NSColor.systemBlue.withAlphaComponent(0.5).cgColor)
    context.setLineWidth(1)
    context.move(to: CGPoint(x: -halfLength, y: -halfBar))
    context.addLine(to: CGPoint(x: halfLength, y: -halfBar))
    context.strokePath()
    context.move(to: CGPoint(x: -halfLength, y: halfBar))
    context.addLine(to: CGPoint(x: halfLength, y: halfBar))
    context.strokePath()

    // Tick marks every 50pt
    context.setStrokeColor(NSColor.systemBlue.withAlphaComponent(0.3).cgColor)
    context.setLineWidth(0.5)
    var x = -halfLength
    while x <= halfLength {
      context.move(to: CGPoint(x: x, y: -halfBar))
      context.addLine(to: CGPoint(x: x, y: -halfBar + 6))
      context.strokePath()
      context.move(to: CGPoint(x: x, y: halfBar))
      context.addLine(to: CGPoint(x: x, y: halfBar - 6))
      context.strokePath()
      x += 50
    }

    context.restoreGState()
  }

  // MARK: - Lasso Drawing

  private func drawLassoPath(_ path: NSBezierPath, in context: CGContext) {
    context.saveGState()

    context.setStrokeColor(NSColor.systemBlue.cgColor)
    context.setLineWidth(1.5)
    context.setLineDash(phase: 0, lengths: [6, 4])
    context.addPath(path.cgPath)
    context.strokePath()

    context.restoreGState()
  }
}
