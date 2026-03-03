import Cocoa
import SwiftUI

/// Signature capture view — modal drawing pad for capturing signatures.
struct SignatureCaptureView: View {
    @Binding var isPresented: Bool
    @State private var signaturePoints: [[CGPoint]] = []
    @State private var currentLine: [CGPoint] = []
    var onSave: (NSImage) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Sign Here")
                .font(.headline)
            
            Canvas { context, size in
                for line in signaturePoints {
                    guard line.count >= 2 else { continue }
                    var path = Path()
                    path.move(to: line[0])
                    for i in 1..<line.count {
                        path.addLine(to: line[i])
                    }
                    context.stroke(path, with: .color(.primary), lineWidth: 2)
                }
                
                if currentLine.count >= 2 {
                    var path = Path()
                    path.move(to: currentLine[0])
                    for i in 1..<currentLine.count {
                        path.addLine(to: currentLine[i])
                    }
                    context.stroke(path, with: .color(.primary), lineWidth: 2)
                }
            }
            .frame(height: 200)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentLine.append(value.location)
                    }
                    .onEnded { _ in
                        signaturePoints.append(currentLine)
                        currentLine = []
                    }
            )
            
            // Signature line
            Rectangle()
                .fill(Color.gray)
                .frame(height: 1)
                .padding(.horizontal, 40)
            
            HStack(spacing: 20) {
                Button("Clear") {
                    signaturePoints.removeAll()
                    currentLine.removeAll()
                }
                .keyboardShortcut(.delete, modifiers: [])
                
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    if let image = renderSignature() {
                        onSave(image)
                    }
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(signaturePoints.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
    
    private func renderSignature() -> NSImage? {
        let size = CGSize(width: 300, height: 150)
        let image = NSImage(size: size)
        image.lockFocus()
        
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }
        
        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineWidth(2)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        for line in signaturePoints {
            guard line.count >= 2 else { continue }
            context.beginPath()
            context.move(to: line[0])
            for i in 1..<line.count {
                context.addLine(to: line[i])
            }
            context.strokePath()
        }
        
        image.unlockFocus()
        return image
    }
}
