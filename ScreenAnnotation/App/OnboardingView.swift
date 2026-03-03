import SwiftUI

struct OnboardingView: View {
    var onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let hotkeys: [(String, String)] = [
        ("⌘⇧D", "Toggle drawing on / off"),
        ("⌘⇧Z", "Undo last stroke"),
        ("⌘⇧E", "Toggle eraser"),
        ("⌘⇧H", "Hide toolbar & cursor (stealth mode)"),
        ("⌘⇧X", "Clear all annotations"),
        ("⌘⇧S", "Snapshot screen to clipboard"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "pencil.tip.crop.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.tint)
                Text("Screen Annotation")
                    .font(.title.bold())
                Text("Draw, highlight, and annotate anything on your screen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            .padding(.horizontal, 32)

            Divider()
                .padding(.vertical, 20)

            // Hotkey list
            VStack(alignment: .leading, spacing: 10) {
                Text("Keyboard Shortcuts")
                    .font(.headline)
                    .padding(.bottom, 2)

                ForEach(hotkeys, id: \.0) { key, description in
                    HStack {
                        Text(key)
                            .font(.system(.body, design: .monospaced).bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(6)
                            .frame(width: 80, alignment: .center)
                        Text(description)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(.horizontal, 32)

            Divider()
                .padding(.vertical, 20)

            // Accessibility note
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lock.shield")
                    .foregroundStyle(.orange)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accessibility Permission")
                        .font(.subheadline.bold())
                    Text("For global hotkeys to work outside Xcode, grant Accessibility access in System Settings → Privacy & Security → Accessibility.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)

            // Start button
            Button {
                onDismiss()
                dismiss()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.top, 20)
            .padding(.bottom, 28)
        }
        .frame(width: 440)
    }
}
