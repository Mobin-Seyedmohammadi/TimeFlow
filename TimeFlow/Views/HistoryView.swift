import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var vm: TimeFlowViewModel
    @State private var selectedTask: TimeFlowTask? = nil
    @State private var filterCategory: TaskCategory? = nil

    private var filteredTasks: [TimeFlowTask] {
        if let cat = filterCategory {
            return vm.completedTasks.filter { $0.category == cat }
        }
        return vm.completedTasks
    }

    var body: some View {
        ZStack {
            Color.tfBackground.ignoresSafeArea()

            if vm.completedTasks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Category filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                filterChip(label: "All", isSelected: filterCategory == nil) {
                                    filterCategory = nil
                                }
                                ForEach(TaskCategory.allCases) { cat in
                                    filterChip(label: cat.rawValue, icon: cat.icon, color: cat.color, isSelected: filterCategory == cat) {
                                        filterCategory = filterCategory == cat ? nil : cat
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                        }

                        // Summary stats
                        if !filteredTasks.isEmpty {
                            TimeFlowCard {
                                HStack(spacing: 0) {
                                    statBlock("\(filteredTasks.count)", label: "Tasks")
                                    Divider().frame(height: 40)
                                    let underestimated = filteredTasks.filter { ($0.estimationDifferenceMinutes ?? 0) > 3 }.count
                                    statBlock("\(underestimated)", label: "Underestimated")
                                    Divider().frame(height: 40)
                                    let accurate = filteredTasks.filter { abs($0.estimationDifferenceMinutes ?? 99) <= 3 }.count
                                    statBlock("\(accurate)", label: "Accurate")
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Task list
                        LazyVStack(spacing: 10) {
                            ForEach(filteredTasks) { task in
                                Button(action: { selectedTask = task }) {
                                    historyRow(task)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 16)
                            }
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedTask) { task in
            NavigationStack {
                TaskDetailView(task: task)
            }
            .environmentObject(vm)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No completed tasks yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.tfDark)
            Text("Complete your first task to see your personal time patterns.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func historyRow(_ task: TimeFlowTask) -> some View {
        TimeFlowCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    StatusChip(category: task.category)
                    Spacer()
                    EstimationLabelChip(label: task.estimationLabel, color: task.estimationLabelColor)
                }

                Text(task.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.tfDark)

                HStack(spacing: 16) {
                    labelValue("Estimate", "\(task.finalEstimateMinutes) min")
                    labelValue("Actual", "\(task.actualDurationMinutes ?? 0) min")
                    if let diff = task.estimationDifferenceMinutes {
                        labelValue("Diff", diff >= 0 ? "+\(diff) min" : "\(diff) min",
                                   valueColor: abs(diff) <= 3 ? Color(hex: "059669") : (diff > 0 ? .tfOrange : .tfBlue))
                    }
                }

                if let date = task.completedAt {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func labelValue(_ label: String, _ value: String, valueColor: Color = .tfDark) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 11)).foregroundColor(.secondary)
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(valueColor)
        }
    }

    private func statBlock(_ value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 22, weight: .bold)).foregroundColor(.tfDark)
            Text(label).font(.system(size: 11)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func filterChip(label: String, icon: String? = nil, color: Color = .tfBlue, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon).font(.system(size: 11))
                }
                Text(label).font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : (icon != nil ? color : .secondary))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? color : Color.tfCard)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? color : Color.black.opacity(0.1), lineWidth: 1))
        }
    }
}
