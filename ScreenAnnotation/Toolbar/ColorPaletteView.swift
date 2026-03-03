import SwiftUI

struct ColorPaletteView: View {
    @Binding var selectedColor: NSColor
    @Binding var strokeWidth: CGFloat
    @Binding var opacity: CGFloat
    @State private var showCustomPicker = false
    
    private let presetColors: [[NSColor]] = [
        [.black, NSColor(red: 0.0, green: 0.2, blue: 0.6, alpha: 1.0),
         NSColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1.0),
         NSColor(red: 0.0, green: 0.7, blue: 0.2, alpha: 1.0)],
        [NSColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0),
         NSColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0),
         .red,
         NSColor(red: 0.9, green: 0.2, blue: 0.6, alpha: 1.0)]
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // Color grid
            VStack(spacing: 6) {
                ForEach(0..<presetColors.count, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(0..<presetColors[row].count, id: \.self) { col in
                            let color = presetColors[row][col]
                            Circle()
                                .fill(Color(nsColor: color))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(isSelected(color) ? Color.white : Color.clear, lineWidth: 2)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(isSelected(color) ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }
            }
            
            // Custom color picker button
            Button(action: { showCustomPicker.toggle() }) {
                HStack {
                    Image(systemName: "eyedropper")
                    Text("Custom Color")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showCustomPicker) {
                CustomColorPickerView(selectedColor: $selectedColor)
            }
            
            Divider()
            
            // Line weight
            VStack(alignment: .leading, spacing: 4) {
                Text("Line Weight")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Image(systemName: "minus")
                        .font(.caption2)
                    Slider(value: $strokeWidth, in: 1...30, step: 0.5)
                    Image(systemName: "plus")
                        .font(.caption2)
                    Text("\(strokeWidth, specifier: "%.1f")")
                        .font(.caption)
                        .frame(width: 30)
                }
            }
            
            // Opacity
            VStack(alignment: .leading, spacing: 4) {
                Text("Opacity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.caption2)
                    Slider(value: $opacity, in: 0.1...1.0, step: 0.05)
                    Text("\(Int(opacity * 100))%")
                        .font(.caption)
                        .frame(width: 35)
                }
            }
        }
        .padding(16)
        .frame(width: 200)
    }
    
    private func isSelected(_ color: NSColor) -> Bool {
        guard let c1 = color.usingColorSpace(.deviceRGB),
              let c2 = selectedColor.usingColorSpace(.deviceRGB) else { return false }
        return abs(c1.redComponent - c2.redComponent) < 0.01 &&
               abs(c1.greenComponent - c2.greenComponent) < 0.01 &&
               abs(c1.blueComponent - c2.blueComponent) < 0.01
    }
}

struct CustomColorPickerView: View {
    @Binding var selectedColor: NSColor
    @State private var swiftUIColor: Color = .red
    
    var body: some View {
        VStack {
            ColorPicker("Choose Color", selection: $swiftUIColor, supportsOpacity: true)
                .labelsHidden()
                .frame(width: 200, height: 200)
        }
        .padding()
        .onChange(of: swiftUIColor) { newValue in
            selectedColor = NSColor(newValue)
        }
        .onAppear {
            swiftUIColor = Color(nsColor: selectedColor)
        }
    }
}
