import Cocoa
import Combine
import ScreenCaptureKit

final class PermissionManager: ObservableObject {

  @Published var accessibilityGranted = false
  @Published var screenRecordingGranted = false

  var allGranted: Bool { accessibilityGranted && screenRecordingGranted }

  private var pollTimer: Timer?

  init() {
    refresh()
  }

  // MARK: - Polling

  func startPolling() {
    stopPolling()
    pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.refresh()
    }
  }

  func stopPolling() {
    pollTimer?.invalidate()
    pollTimer = nil
  }

  // MARK: - Status checks

  func refresh() {
    accessibilityGranted = AXIsProcessTrusted()
    checkScreenRecordingAsync()
  }

  private func checkScreenRecordingAsync() {
    Task {
      do {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        let granted = !content.displays.isEmpty
        await MainActor.run { [granted] in
          self.screenRecordingGranted = granted
        }
      } catch {
        await MainActor.run {
          self.screenRecordingGranted = false
        }
      }
    }
  }

  // MARK: - Prompt / open settings

  func promptAccessibility() {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
    AXIsProcessTrustedWithOptions(options)
  }

  func openAccessibilitySettings() {
    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
    NSWorkspace.shared.open(url)
  }

  func openScreenRecordingSettings() {
    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
    NSWorkspace.shared.open(url)
  }
}
