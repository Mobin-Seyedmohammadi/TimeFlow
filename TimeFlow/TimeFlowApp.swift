import SwiftUI
import UserNotifications

@main
struct TimeFlowApp: App {
    @StateObject private var vm = TimeFlowViewModel()

    init() {
        // Request push notification permission on first launch.
        // The user sees the system dialog once; subsequent launches skip it.
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(vm)
                .preferredColorScheme(.light)
        }
    }
}
