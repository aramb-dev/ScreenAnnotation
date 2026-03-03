import Cocoa

/// Renders clean vector shapes using Core Graphics (overlaid on Metal canvas).
class ShapeRenderer {
    
    static func render(_ shape: ShapeAnnotation, in context: CGContext) {
        context.saveGState()
        context.setAlpha(shape.opacity)
        
        let cgPath = shape.path.cgPath
        
        if let fillColor = shape.fillColor {
            context.setFillColor(fillColor.cgColor)
            context.addPath(cgPath)
            context.fillPath()
        }
        
        context.setStrokeColor(shape.borderColor.cgColor)
        context.setLineWidth(shape.borderWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.addPath(cgPath)
        context.strokePath()
        
        context.restoreGState()
    }
    
    static func renderHandles(_ shape: ShapeAnnotation, in context: CGContext) {
        let handleSize: CGFloat = 8
        let handleColor = NSColor.systemGreen
        
        context.saveGState()
        context.setFillColor(handleColor.cgColor)
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(1)
        
        for position in shape.handlePositions {
            let handleRect = CGRect(
                x: position.x - handleSize / 2,
                y: position.y - handleSize / 2,
                width: handleSize,
                height: handleSize
            )
            context.fillEllipse(in: handleRect)
            context.strokeEllipse(in: handleRect)
        }
        
        context.restoreGState()
    }
}

// MARK: - NSBezierPath → CGPath conversion

extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0..<elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo, .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            @unknown default:
                break
            }
        }
        
        return path
    }
}
