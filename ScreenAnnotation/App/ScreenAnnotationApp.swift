import SwiftUI

@main
struct ScreenAnnotationApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Onboarding window — always opens on launch.
        Window("Welcome to Screen Annotation", id: "onboarding") {
            OnboardingView {
                // Keep the app active after onboarding so the toolbar stays visible.
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Settings {
            EmptyView()
        }
    }
}
