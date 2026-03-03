import SwiftUI

/// Style controls for shapes and text annotations.
struct ShapeStyleControls: View {
    @Binding var borderColor: NSColor
    @Binding var fillColor: NSColor?
    @Binding var borderWidth: CGFloat
    @Binding var opacity: CGFloat
    
    @State private var hasFill: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Shape Style")
                .font(.headline)
            
            // Border color
            HStack {
                Text("Border")
                    .font(.caption)
                    .frame(width: 50, alignment: .leading)
                ColorPicker("", selection: Binding(
                    get: { Color(nsColor: borderColor) },
                    set: { borderColor = NSColor($0) }
                ))
                .labelsHidden()
            }
            
            // Fill
            HStack {
                Toggle("Fill", isOn: $hasFill)
                    .font(.caption)
                if hasFill {
                    ColorPicker("", selection: Binding(
                        get: { Color(nsColor: fillColor ?? .clear) },
                        set: { fillColor = NSColor($0) }
                    ))
                    .labelsHidden()
                }
            }
            .onChange(of: hasFill) { newValue in
                fillColor = newValue ? .systemBlue : nil
            }
            
            // Border width
            HStack {
                Text("Width")
                    .font(.caption)
                    .frame(width: 50, alignment: .leading)
                Slider(value: $borderWidth, in: 1...10, step: 0.5)
                Text("\(borderWidth, specifier: "%.1f")")
                    .font(.caption)
                    .frame(width: 25)
            }
            
            // Opacity
            HStack {
                Text("Opacity")
                    .font(.caption)
                    .frame(width: 50, alignment: .leading)
                Slider(value: $opacity, in: 0.1...1.0, step: 0.05)
                Text("\(Int(opacity * 100))%")
                    .font(.caption)
                    .frame(width: 35)
            }
        }
        .padding(12)
        .frame(width: 220)
    }
}

struct TextStyleControls: View {
    @Binding var fontName: String
    @Binding var fontSize: CGFloat
    @Binding var textColor: NSColor
    @Binding var isBold: Bool
    @Binding var isItalic: Bool
    @Binding var alignment: NSTextAlignment
    
    private let fontNames = ["Helvetica", "Arial", "Times New Roman", "Courier", "Georgia", "Menlo"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Text Style")
                .font(.headline)
            
            // Font
            Picker("Font", selection: $fontName) {
                ForEach(fontNames, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .font(.caption)
            
            // Size
            HStack {
                Text("Size")
                    .font(.caption)
                    .frame(width: 40, alignment: .leading)
                Slider(value: $fontSize, in: 8...72, step: 1)
                Text("\(Int(fontSize))")
                    .font(.caption)
                    .frame(width: 25)
            }
            
            // Color
            HStack {
                Text("Color")
                    .font(.caption)
                    .frame(width: 40, alignment: .leading)
                ColorPicker("", selection: Binding(
                    get: { Color(nsColor: textColor) },
                    set: { textColor = NSColor($0) }
                ))
                .labelsHidden()
            }
            
            // Style toggles
            HStack(spacing: 8) {
                Toggle("B", isOn: $isBold)
                    .font(.caption.bold())
                    .toggleStyle(.button)
                
                Toggle("I", isOn: $isItalic)
                    .font(.caption.italic())
                    .toggleStyle(.button)
            }
            
            // Alignment
            Picker("Align", selection: $alignment) {
                Image(systemName: "text.alignleft").tag(NSTextAlignment.left)
                Image(systemName: "text.aligncenter").tag(NSTextAlignment.center)
                Image(systemName: "text.alignright").tag(NSTextAlignment.right)
            }
            .pickerStyle(.segmented)
            .font(.caption)
        }
        .padding(12)
        .frame(width: 220)
    }
}
