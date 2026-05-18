import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: TimeFlowViewModel
    @State private var showResetAlert = false

    private let thresholdOptions: [(label: String, value: Double)] = [
        ("80%", 0.80), ("85%", 0.85), ("90%", 0.90), ("95%", 0.95)
    ]

    var body: some View {
        ZStack {
            Color.tfBackground.ignoresSafeArea()

            List {
                // Timer behavior
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Warning Threshold")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.tfDark)
                        Text("Show near-time warning when this % of estimate is used")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            ForEach(thresholdOptions, id: \.label) { option in
                                Button(action: { vm.warningThreshold = option.value }) {
                                    Text(option.label)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(vm.warningThreshold == option.value ? .white : .tfBlue)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 38)
                                        .background(vm.warningThreshold == option.value ? Color.tfBlue : Color.tfBlue.opacity(0.08))
                                        .cornerRadius(9)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Timer Behavior")
                }

                // AI settings
                Section {
                    Toggle(isOn: $vm.showAIExplanation) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show AI Explanations")
                                .font(.system(size: 15))
                            Text("Display reasoning behind AI time suggestions")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.tfBlue)

                    Picker("Default Category", selection: $vm.defaultCategory) {
                        ForEach(TaskCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                } header: {
                    Text("AI Settings")
                }

                // Prototype
                Section {
                    Toggle(isOn: $vm.simulatedNotifications) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("In-App Warning Cards")
                                .font(.system(size: 15))
                            Text("Show warning cards instead of system notifications")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.tfBlue)

                    Toggle(isOn: $vm.prototypeMode) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Prototype Fast Timer")
                                .font(.system(size: 15))
                            Text("1 real second = 1 simulated minute (for demos)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.tfOrange)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Completed Tasks")
                                .font(.system(size: 15))
                            Text("\(vm.completedTasks.count) tasks in history")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: { showResetAlert = true }) {
                            Text("Reset Data")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "DC2626"))
                        }
                    }
                } header: {
                    Text("Prototype Mode")
                }

                // Prototype notes
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        noteItem(
                            icon: "cpu",
                            color: .tfBlue,
                            title: "Simulated AI",
                            body: "The AI suggestions in TimeFlow are simulated using local rules and mock data. There is no real machine learning or server involved."
                        )
                        Divider()
                        noteItem(
                            icon: "externaldrive",
                            color: Color(hex: "7C3AED"),
                            title: "Local Data Only",
                            body: "All data is stored locally on this device during the session. No data is sent to any server."
                        )
                        Divider()
                        noteItem(
                            icon: "exclamationmark.triangle",
                            color: .tfOrange,
                            title: "Prototype Limitations",
                            body: "Suggestions may be imperfect. The goal is to test the interaction flow and user understanding — not real AI accuracy."
                        )
                        Divider()
                        noteItem(
                            icon: "person.2.fill",
                            color: Color(hex: "059669"),
                            title: "Evaluation Goal",
                            body: "This prototype tests whether users understand the estimate → timer → reflection cycle. Observers should note where users hesitate or tap the wrong control."
                        )
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Prototype Notes")
                }

                // About
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "timer")
                                .font(.system(size: 24))
                                .foregroundColor(.tfBlue)
                            VStack(alignment: .leading) {
                                Text("TimeFlow").font(.system(size: 17, weight: .bold))
                                Text("HCI Course Prototype • v1.0").font(.system(size: 12)).foregroundColor(.secondary)
                            }
                        }
                        Text("TimeFlow helps you compare your time estimates with AI suggestions, track actual duration, and reflect on your personal time estimation patterns.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("About TimeFlow")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.tfBackground)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Reset All Data?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) { vm.resetPrototypeData() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently clear all saved task history and start fresh. The active task will also be discarded.")
        }
    }

    private func noteItem(icon: String, color: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 22)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.tfDark)
                Text(body)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
