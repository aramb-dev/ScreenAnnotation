import Cocoa
import SwiftUI
import Carbon.HIToolbox

class AppDelegate: NSObject, NSApplicationDelegate {

  private var overlayControllers: [OverlayPanelController] = []
  private var toolbarController: ToolbarPanelController?
  private var hotkeyManager: HotkeyManager?
  private var statusItem: NSStatusItem?
  private var drawingEnabled = false
  private var localKeyMonitor: Any?
  private var globalKeyMonitor: Any?
  private var toggleDrawingMenuItem: NSMenuItem?

  private var onboardingWindow: NSWindow?
  private let permissionManager = PermissionManager()

  private var hasCompletedOnboarding: Bool {
    get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
    set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }

  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    true
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    setupStatusBarItem()

    if hasCompletedOnboarding {
      activateApp()
    } else {
      showOnboardingWindow()
    }
  }

  // MARK: - Activation (post-onboarding)

  private func activateApp() {
    setupOverlays()
    setupLocalHotkey()
    setupHotkeysDeferred()
  }

  func completeOnboarding() {
    hasCompletedOnboarding = true
    onboardingWindow?.close()
    onboardingWindow = nil
    activateApp()
  }

  // MARK: - Onboarding Window

  func showOnboardingWindow() {
    if let existing = onboardingWindow {
      existing.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }

    let view = OnboardingView(permissions: permissionManager) { [weak self] in
      self?.completeOnboarding()
    }

    let hostingController = NSHostingController(rootView: view)
    let window = NSWindow(contentViewController: hostingController)
    window.title = "Welcome to Screen Annotation"
    window.styleMask = [.titled, .closable]
    window.isReleasedWhenClosed = false
    window.center()
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)

    onboardingWindow = window
  }

  // MARK: - Status Bar

  private func setupStatusBarItem() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    if let button = statusItem?.button {
      button.image = NSImage(systemSymbolName: "pencil.tip.crop.circle", accessibilityDescription: "Screen Annotation")
    }

    let menu = NSMenu()

    let toggleItem = NSMenuItem(title: "Start Drawing (⌘⇧D)", action: #selector(toggleDrawing), keyEquivalent: "")
    toggleDrawingMenuItem = toggleItem
    menu.addItem(toggleItem)

    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Clear All", action: #selector(clearAll), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Toggle Toolbar", action: #selector(toggleToolbarAction), keyEquivalent: ""))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Permissions…", action: #selector(showPermissions), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Show Welcome", action: #selector(showWelcome), keyEquivalent: ""))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
    statusItem?.menu = menu
  }

  // MARK: - Overlay Setup

  private func setupOverlays() {
    for screen in NSScreen.screens {
      let controller = OverlayPanelController(screen: screen)
      controller.showOverlay()
      overlayControllers.append(controller)
    }

    toolbarController = ToolbarPanelController(
      canvasManager: overlayControllers.first?.canvasManager
    )
    toolbarController?.showToolbar()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleDrawingToggleFromToolbar),
      name: .drawingToggled,
      object: nil
    )
  }

  @objc private func handleDrawingToggleFromToolbar() {
    guard let manager = overlayControllers.first?.canvasManager else { return }
    drawingEnabled = manager.isDrawingEnabled
    overlayControllers.forEach { $0.panel.ignoresMouseEvents = !drawingEnabled }
    updateDrawingUI(enabled: drawingEnabled)
  }

  private func updateDrawingUI(enabled: Bool) {
    toggleDrawingMenuItem?.title = enabled ? "Stop Drawing (⌘⇧D)" : "Start Drawing (⌘⇧D)"
    let icon = enabled ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle"
    let desc = enabled ? "Drawing Active" : "Screen Annotation"
    statusItem?.button?.image = NSImage(systemSymbolName: icon, accessibilityDescription: desc)
  }

  // MARK: - Hotkeys (NSEvent monitors — no Accessibility permission required)

  private func setupLocalHotkey() {
    globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
      self?.handleKeyEvent(event)
    }

    localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      if self?.handleKeyEvent(event) == true {
        return nil
      }
      return event
    }
  }

  @discardableResult
  private func handleKeyEvent(_ event: NSEvent) -> Bool {
    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    let hasCmd = flags.contains(.command)
    let hasShift = flags.contains(.shift)

    guard hasCmd && hasShift else { return false }

    switch Int(event.keyCode) {
    case kVK_ANSI_D:
      toggleDrawing()
      return true
    case kVK_ANSI_Z:
      overlayControllers.forEach { $0.canvasManager?.undo() }
      return true
    case kVK_ANSI_E:
      overlayControllers.forEach { $0.canvasManager?.toggleEraser() }
      return true
    case kVK_ANSI_H:
      toggleStealth()
      return true
    case kVK_ANSI_X:
      clearAll()
      return true
    default:
      return false
    }
  }

  // MARK: - CGEvent Tap (optional — elevates hotkeys to work in secure input fields)

  private func setupHotkeysDeferred() {
    hotkeyManager = HotkeyManager()
    hotkeyManager?.onToggleStealth = { [weak self] in self?.toggleStealth() }
    hotkeyManager?.onUndo = { [weak self] in
      self?.overlayControllers.forEach { $0.canvasManager?.undo() }
    }
    hotkeyManager?.onClearAll = { [weak self] in self?.clearAll() }
    hotkeyManager?.onToggleEraser = { [weak self] in
      self?.overlayControllers.forEach { $0.canvasManager?.toggleEraser() }
    }

    if !hotkeyManager!.start() {
      print("[AppDelegate] Accessibility not granted — hotkeys work via NSEvent monitors.")
    }
  }

  // MARK: - Actions

  @objc private func toggleDrawing() {
    drawingEnabled.toggle()
    overlayControllers.forEach { $0.setDrawingEnabled(drawingEnabled) }
    updateDrawingUI(enabled: drawingEnabled)
  }

  @objc private func clearAll() {
    for controller in overlayControllers {
      controller.canvasManager?.clearAll()
    }
  }

  @objc private func toggleToolbarAction() {
    toolbarController?.toggleVisibility()
  }

  private func toggleStealth() {
    toolbarController?.toggleVisibility()
    for controller in overlayControllers {
      controller.toggleCursorVisibility()
    }
  }

  @objc private func showPermissions() {
    // Re-use onboarding window starting at permissions step
    showOnboardingWindow()
  }

  @objc private func showWelcome() {
    showOnboardingWindow()
  }

  @objc private func quitApp() {
    [globalKeyMonitor, localKeyMonitor].compactMap { $0 }.forEach { NSEvent.removeMonitor($0) }
    NSApplication.shared.terminate(nil)
  }
}
