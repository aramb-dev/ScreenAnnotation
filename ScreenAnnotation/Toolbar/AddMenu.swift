import SwiftUI

struct AddMenuView: View {
    @ObservedObject var canvasManager: CanvasManager
    @Binding var showSignatureCapture: Bool
    @State private var showShapeSubmenu = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Add Text
            MenuButton(icon: "textformat", label: "Add Text") {
                canvasManager.activeTool = .text
            }
            
            Divider()
            
            // Add Shape
            MenuButton(icon: "square.on.circle", label: "Add Shape") {
                showShapeSubmenu.toggle()
            }
            .popover(isPresented: $showShapeSubmenu) {
                ShapeSubmenuView(canvasManager: canvasManager)
            }
            
            Divider()
            
            // Add Signature
            MenuButton(icon: "signature", label: "Add Signature") {
                showSignatureCapture = true
            }
        }
        .padding(8)
        .frame(width: 180)
    }
}

struct MenuButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(label)
                    .font(.system(size: 13))
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .cornerRadius(4)
    }
}

struct ShapeSubmenuView: View {
    @ObservedObject var canvasManager: CanvasManager
    
    private let shapes: [(String, String, RecognizedShapeType)] = [
        ("rectangle", "Rectangle", .rectangle),
        ("circle", "Circle", .circle),
        ("arrow.right", "Arrow", .arrow),
        ("line.diagonal", "Line", .line),
        ("triangle", "Triangle", .triangle),
        ("star", "Star", .star),
        ("bubble.left", "Speech Bubble", .speechBubble),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(shapes, id: \.1) { icon, label, shapeType in
                Button(action: {
                    canvasManager.selectedShapeType = shapeType
                    canvasManager.activeTool = .shape
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .frame(width: 20)
                        Text(label)
                            .font(.system(size: 13))
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .frame(width: 160)
    }
}
