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
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // The app uses NSPanels (overlay + toolbar) that don't count as "windows".
        // Keep running after the onboarding window is closed.
        return false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBarItem()
        setupOverlays()
        setupLocalHotkey()
        setupHotkeysDeferred()

        // Bring the app to the front so the onboarding window / toolbar is visible.
        NSApp.activate(ignoringOtherApps: true)
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
        // Toolbar starts visible so the user can see the app launched,
        // but drawing is OFF — clicks pass through to underlying apps.
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
        // NSEvent monitors work without Accessibility permission.
        // Global monitor fires when another app is frontmost.
        // Local monitor fires when our own panels are key (e.g. toolbar focused).
        
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil // consume the event
            }
            return event
        }
    }
    
    /// Returns true if the event was handled (consumed).
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
        // CGEvent tap handles edge cases NSEvent global monitor can't (e.g. secure input fields).
        // It requires Accessibility permission. If not granted we silently skip it —
        // NSEvent monitors above already cover all hotkeys for normal use.
        hotkeyManager = HotkeyManager()
        hotkeyManager?.onToggleStealth = { [weak self] in self?.toggleStealth() }
        hotkeyManager?.onUndo = { [weak self] in
            self?.overlayControllers.forEach { $0.canvasManager?.undo() }
        }
        hotkeyManager?.onClearAll = { [weak self] in self?.clearAll() }
        hotkeyManager?.onToggleEraser = { [weak self] in
            self?.overlayControllers.forEach { $0.canvasManager?.toggleEraser() }
        }
        
        // Attempt once. If Accessibility isn't granted just rely on NSEvent monitors.
        if !hotkeyManager!.start() {
            print("[AppDelegate] Accessibility not granted — hotkeys work via NSEvent monitors (fine for most use).")
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
    
    @objc private func quitApp() {
        [globalKeyMonitor, localKeyMonitor].compactMap { $0 }.forEach { NSEvent.removeMonitor($0) }
        NSApplication.shared.terminate(nil)
    }
}
