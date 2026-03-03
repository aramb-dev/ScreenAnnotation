import Cocoa
import Vision

/// Scribble Tool — handwriting → typed text conversion using macOS Vision framework.
class ScribbleTool {
    
    /// Converts handwritten stroke points into recognized text.
    func recognizeText(from strokes: [Stroke], in bounds: CGRect, completion: @escaping (String?) -> Void) {
        // Render strokes to an image for Vision recognition
        guard let image = renderStrokesToImage(strokes, bounds: bounds) else {
            completion(nil)
            return
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion(nil)
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            DispatchQueue.main.async {
                completion(recognizedText.isEmpty ? nil : recognizedText)
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
    
    /// Renders strokes onto an NSImage for Vision processing.
    private func renderStrokesToImage(_ strokes: [Stroke], bounds: CGRect) -> NSImage? {
        let size = bounds.size
        guard size.width > 0 && size.height > 0 else { return nil }
        
        let image = NSImage(size: size)
        image.lockFocus()
        
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }
        
        // White background for text recognition
        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Draw strokes in black
        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        for stroke in strokes {
            let pts = stroke.activePoints
            guard pts.count >= 2 else { continue }
            context.setLineWidth(2.0)
            context.beginPath()
            context.move(to: CGPoint(x: pts[0].position.x - bounds.minX, y: pts[0].position.y - bounds.minY))
            pts.dropFirst().forEach { p in
                context.addLine(to: CGPoint(x: p.position.x - bounds.minX, y: p.position.y - bounds.minY))
            }
            context.strokePath()
        }
        
        image.unlockFocus()
        return image
    }
}
