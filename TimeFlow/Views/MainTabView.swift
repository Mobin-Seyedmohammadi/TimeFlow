import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var vm: TimeFlowViewModel
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("Today", systemImage: "sun.max.fill")
            }
            .tag(0)

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "list.bullet.rectangle")
            }
            .tag(1)

            NavigationStack {
                InsightsView()
            }
            .tabItem {
                Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(2)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
        .accentColor(.tfBlue)
        // Present new task sheet at root level so it covers everything
        .sheet(isPresented: $vm.showNewTaskSheet) {
            NavigationStack {
                NewTaskView()
                    .navigationDestination(isPresented: $vm.showEstimateReview) {
                        EstimateReviewView()
                    }
            }
            .environmentObject(vm)
        }
        // Full-screen cover for active timer
        .fullScreenCover(isPresented: $vm.showActiveTask) {
            NavigationStack {
                ActiveTaskView()
            }
            .environmentObject(vm)
        }
        // Full-screen cover for reflection
        .fullScreenCover(isPresented: $vm.showReflection) {
            NavigationStack {
                ReflectionView()
            }
            .environmentObject(vm)
        }
    }
}
