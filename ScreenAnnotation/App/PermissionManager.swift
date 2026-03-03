import Cocoa
import Combine
import ScreenCaptureKit

final class PermissionManager: ObservableObject {

  @Published var accessibilityGranted = false
  @Published var screenRecordingGranted = false

  var allGranted: Bool { accessibilityGranted && screenRecordingGranted }

  private var pollTimer: Timer?
  private var screenRecordingTask: Task<Void, Never>?

  init() {
    refresh()
  }

  deinit {
    stopPolling()
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
    screenRecordingTask?.cancel()
    screenRecordingTask = nil
  }

  // MARK: - Status checks

  func refresh() {
    accessibilityGranted = AXIsProcessTrusted()
    checkScreenRecordingAsync()
  }

  private func checkScreenRecordingAsync() {
    screenRecordingTask?.cancel()
    screenRecordingTask = Task { [weak self] in
      do {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard !Task.isCancelled else { return }
        let granted = !content.displays.isEmpty
        await MainActor.run {
          self?.screenRecordingGranted = granted
        }
      } catch {
        guard !Task.isCancelled else { return }
        await MainActor.run {
          self?.screenRecordingGranted = false
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
