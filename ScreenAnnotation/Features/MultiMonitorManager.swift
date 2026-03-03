import Cocoa

/// Manages overlay panels across multiple displays.
class MultiMonitorManager {
    
    private(set) var overlayControllers: [OverlayPanelController] = []
    
    /// Creates an overlay for each connected display.
    func setupOverlays() -> [OverlayPanelController] {
        overlayControllers.removeAll()
        
        for screen in NSScreen.screens {
            let controller = OverlayPanelController(screen: screen)
            overlayControllers.append(controller)
        }
        
        return overlayControllers
    }
    
    /// Shows overlays on all screens.
    func showAll() {
        for controller in overlayControllers {
            controller.showOverlay()
        }
    }
    
    /// Hides overlays on all screens.
    func hideAll() {
        for controller in overlayControllers {
            controller.hideOverlay()
        }
    }
    
    func showOnly(screenIndex: Int) {
        hideAll()
        if screenIndex < overlayControllers.count {
            overlayControllers[screenIndex].showOverlay()
        }
    }
    
    /// Returns screen names for UI display.
    var screenNames: [String] {
        NSScreen.screens.enumerated().map { index, screen in
            let name = screen.localizedName
            return index == 0 ? "\(name) (Primary)" : name
        }
    }
    
    /// Handles display configuration changes.
    func observeDisplayChanges(callback: @escaping () -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            callback()
        }
    }
}
