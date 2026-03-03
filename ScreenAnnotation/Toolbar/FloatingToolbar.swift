import SwiftUI

struct FloatingToolbar: View {
    @ObservedObject var canvasManager: CanvasManager
    @State private var showColorPicker = false
    @State private var showAddMenu = false
    @State private var showSignatureCapture = false
    
    var body: some View {
        // Center the toolbar pill in whatever frame the NSHostingView gives us.
        // The NSPanel itself is draggable via isMovableByWindowBackground.
        ZStack {
            toolbarContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showSignatureCapture) {
            SignatureCaptureView(isPresented: $showSignatureCapture) { image in
                SignatureStore().save(signature: image)
            }
        }
    }
    
    @ViewBuilder
    private var toolbarContent: some View {
        let hstack = HStack(spacing: 4) {
            // Drawing on/off toggle
            ToolButton(
                icon: canvasManager.isDrawingEnabled ? "hand.draw.fill" : "hand.draw",
                label: canvasManager.isDrawingEnabled ? "Stop Drawing (⌘⇧D)" : "Start Drawing (⌘⇧D)",
                isSelected: canvasManager.isDrawingEnabled
            ) {
                canvasManager.toggleDrawing()
                NotificationCenter.default.post(name: .drawingToggled, object: nil)
            }
            
            Divider().frame(height: 28).padding(.horizontal, 2)
            
            drawingToolsGroup
            
            Divider().frame(height: 28).padding(.horizontal, 2)
            
            ToolButton(icon: "eraser", label: "Eraser",
                       isSelected: canvasManager.activeTool == .eraser) {
                canvasManager.selectEraser()
            }
            ToolButton(icon: "lasso", label: "Lasso",
                       isSelected: canvasManager.activeTool == .lasso) {
                canvasManager.selectLasso()
            }
            ToolButton(icon: "ruler", label: "Ruler",
                       isSelected: canvasManager.activeTool == .ruler) {
                canvasManager.selectRuler()
            }
            
            Divider().frame(height: 28).padding(.horizontal, 2)
            
            ColorButton(color: canvasManager.currentColor) {
                showColorPicker.toggle()
            }
            .popover(isPresented: $showColorPicker) {
                ColorPaletteView(
                    selectedColor: Binding(
                        get: { canvasManager.currentColor },
                        set: { canvasManager.currentColor = $0 }
                    ),
                    strokeWidth: Binding(
                        get: { canvasManager.currentWidth },
                        set: { canvasManager.currentWidth = $0 }
                    ),
                    opacity: Binding(
                        get: { canvasManager.currentOpacity },
                        set: { canvasManager.currentOpacity = $0 }
                    )
                )
            }
            
            ToolButton(icon: "plus.circle", label: "Add") {
                showAddMenu.toggle()
            }
            .popover(isPresented: $showAddMenu) {
                AddMenuView(
                    canvasManager: canvasManager,
                    showSignatureCapture: $showSignatureCapture
                )
            }
            
            Divider().frame(height: 28).padding(.horizontal, 2)
            
            ToolButton(icon: "arrow.uturn.backward", label: "Undo") {
                canvasManager.undo()
            }
            ToolButton(icon: "arrow.uturn.forward", label: "Redo") {
                canvasManager.redo()
            }
            ToolButton(icon: "trash", label: "Clear") {
                canvasManager.clearAll()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        
        if #available(macOS 26.0, *) {
            hstack
                .glassEffect(in: Capsule())
        } else {
            hstack
                .background(
                    VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                        .clipShape(Capsule())
                )
                .overlay(Capsule().stroke(Color.gray.opacity(0.3), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
        }
    }
    
    private var drawingToolsGroup: some View {
        HStack(spacing: 2) {
            ForEach(PenType.allCases) { penType in
                ToolButton(
                    icon: iconName(for: penType),
                    label: penType.displayName,
                    isSelected: canvasManager.activeTool == .drawing(penType)
                ) {
                    canvasManager.selectPen(penType)
                }
            }
        }
    }
    
    private func iconName(for penType: PenType) -> String {
        switch penType {
        case .pen: return "pencil.tip"
        case .fineTip: return "pencil.tip.crop.circle"
        case .highlighter: return "highlighter"
        case .pencil: return "pencil"
        case .crayon: return "pencil.and.outline"
        case .calligraphy: return "textformat"
        case .watercolor: return "paintbrush"
        case .laserPointer: return "light.max"
        }
    }
}

// MARK: - Tool Button

struct ToolButton: View {
    let icon: String
    let label: String
    var isSelected: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 28, height: 28)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(label)
    }
}

// MARK: - Color Button

struct ColorButton: View {
    let color: NSColor
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(nsColor: color))
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.1), radius: 1)
        }
        .buttonStyle(.plain)
        .help("Color")
    }
}

// MARK: - Notification for drawing toggle from toolbar

extension Notification.Name {
    static let drawingToggled = Notification.Name("drawingToggled")
}

// MARK: - Visual Effect Blur (NSVisualEffectView wrapper, for pre-macOS 26 fallback)

struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
