import SwiftUI

struct OnboardingView: View {
  @ObservedObject var permissions: PermissionManager
  var initialStep: Int = 0
  var onComplete: () -> Void

  @State private var step = 0
  private let totalSteps = 4

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
      // Content area
      Group {
        switch step {
        case 0: welcomeStep
        case 1: permissionsStep
        case 2: shortcutsStep
        case 3: readyStep
        default: EmptyView()
        }
      }
      .frame(maxWidth: .infinity)

      Spacer(minLength: 0)

      // Navigation
      VStack(spacing: 16) {
        // Dot indicators
        HStack(spacing: 8) {
          ForEach(0..<totalSteps, id: \.self) { i in
            Circle()
              .fill(i == step ? Color.accentColor : Color.secondary.opacity(0.3))
              .frame(width: 7, height: 7)
          }
        }

        // Buttons
        HStack {
          if step > 0 {
            Button("Back") { step -= 1 }
              .buttonStyle(.bordered)
          }
          Spacer()
          if step < totalSteps - 1 {
            Button("Next") { step += 1 }
              .buttonStyle(.borderedProminent)
          } else {
            Button("Get Started") { onComplete() }
              .buttonStyle(.borderedProminent)
          }
        }
      }
      .padding(.horizontal, 32)
      .padding(.bottom, 24)
    }
    .frame(width: 480, height: 420)
    .onAppear {
      step = initialStep
      permissions.startPolling()
    }
    .onDisappear { permissions.stopPolling() }
  }

  // MARK: - Steps

  private var welcomeStep: some View {
    VStack(spacing: 12) {
      Spacer()
      Image(systemName: "pencil.tip.crop.circle.fill")
        .font(.system(size: 64))
        .foregroundStyle(.tint)
      Text("Screen Annotation")
        .font(.largeTitle.bold())
      Text("Draw, highlight, and annotate anything on your screen.")
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      Spacer()
    }
    .padding(.horizontal, 32)
  }

  private var permissionsStep: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Permissions")
        .font(.title2.bold())
        .padding(.top, 28)

      Text("Screen Annotation needs two permissions to work fully.")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      // Accessibility
      permissionRow(
        granted: permissions.accessibilityGranted,
        title: "Accessibility",
        description: "Required for global keyboard shortcuts.",
        action: { permissions.openAccessibilitySettings() }
      )

      // Screen Recording
      permissionRow(
        granted: permissions.screenRecordingGranted,
        title: "Screen Recording",
        description: "Required for screen snapshots.",
        action: { permissions.openScreenRecordingSettings() }
      )

      Text("You can grant these later in System Settings → Privacy & Security.")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .padding(.horizontal, 32)
  }

  private var shortcutsStep: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Keyboard Shortcuts")
        .font(.title2.bold())
        .padding(.top, 28)

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
  }

  private var readyStep: some View {
    VStack(spacing: 16) {
      Spacer()
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 56))
        .foregroundStyle(.green)
      Text("You're All Set!")
        .font(.title.bold())

      VStack(alignment: .leading, spacing: 8) {
        statusLine(granted: permissions.accessibilityGranted, label: "Accessibility")
        statusLine(granted: permissions.screenRecordingGranted, label: "Screen Recording")
      }
      .padding(.top, 4)

      if !permissions.allGranted {
        Text("Some permissions are not granted yet — hotkeys and snapshots may be limited.")
          .font(.caption)
          .foregroundStyle(.orange)
          .multilineTextAlignment(.center)
      }
      Spacer()
    }
    .padding(.horizontal, 32)
  }

  // MARK: - Helpers

  private func permissionRow(
    granted: Bool,
    title: String,
    description: String,
    action: @escaping () -> Void
  ) -> some View {
    HStack(spacing: 12) {
      Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
        .foregroundStyle(granted ? .green : .red)
        .font(.title2)
      VStack(alignment: .leading, spacing: 2) {
        Text(title).font(.headline)
        Text(description).font(.caption).foregroundStyle(.secondary)
      }
      Spacer()
      if !granted {
        Button("Open Settings", action: action)
          .buttonStyle(.bordered)
          .controlSize(.small)
      }
    }
    .padding(12)
    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
  }

  private func statusLine(granted: Bool, label: String) -> some View {
    HStack(spacing: 8) {
      Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle")
        .foregroundStyle(granted ? .green : .secondary)
      Text(label)
        .foregroundStyle(granted ? .primary : .secondary)
    }
  }
}
