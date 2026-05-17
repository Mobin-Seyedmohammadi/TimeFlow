import SwiftUI

@main
struct TimeFlowApp: App {
    @StateObject private var vm = TimeFlowViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(vm)
                .preferredColorScheme(.light)
        }
    }
}
