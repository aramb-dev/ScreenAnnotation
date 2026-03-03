import Cocoa
import Carbon.HIToolbox

/// Manages global hotkeys using CGEvent tap.
/// Requires Accessibility permission.
class HotkeyManager {
    
    var onToggleStealth: (() -> Void)?
    var onUndo: (() -> Void)?
    var onClearAll: (() -> Void)?
    var onToggleEraser: (() -> Void)?
    var onSnapshot: (() -> Void)?
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    deinit {
        stop()
    }
    
    /// Starts listening for global hotkeys. Returns false if accessibility permission is not granted.
    @discardableResult
    func start() -> Bool {
        // Check silently first. Only prompt the system dialog if not yet trusted,
        // and only do it once (the AppDelegate no longer retries, so this fires at most once).
        let trusted = AXIsProcessTrusted()
        if !trusted {
            // Prompt once so the user sees the system dialog
            let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            print("[HotkeyManager] Accessibility permission not granted — prompted user")
            return false
        }
        
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passRetained(event) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
            return manager.handleEvent(proxy: proxy, type: type, event: event)
        }
        
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: refcon
        )
        
        guard let eventTap = eventTap else {
            print("[HotkeyManager] Failed to create event tap")
            return false
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("[HotkeyManager] Global hotkeys active")
        return true
    }
    
    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else { return Unmanaged.passRetained(event) }
        
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        
        let hasCmd = flags.contains(.maskCommand)
        let hasShift = flags.contains(.maskShift)
        
        guard hasCmd && hasShift else { return Unmanaged.passRetained(event) }
        
        switch keyCode {
        case kVK_ANSI_H:
            DispatchQueue.main.async { [weak self] in self?.onToggleStealth?() }
            return nil
        case kVK_ANSI_Z:
            DispatchQueue.main.async { [weak self] in self?.onUndo?() }
            return nil
        case kVK_ANSI_X:
            DispatchQueue.main.async { [weak self] in self?.onClearAll?() }
            return nil
        case kVK_ANSI_E:
            DispatchQueue.main.async { [weak self] in self?.onToggleEraser?() }
            return nil
        case kVK_ANSI_S:
            DispatchQueue.main.async { [weak self] in self?.onSnapshot?() }
            return nil
        default:
            return Unmanaged.passRetained(event)
        }
    }
}
