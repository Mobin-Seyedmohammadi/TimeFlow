import Foundation

struct MockData {
    static let completedTasks: [TimeFlowTask] = [
        TimeFlowTask(
            id: UUID(),
            title: "Study AI slides",
            category: .study,
            userEstimateMinutes: 45,
            aiSuggestedMinutes: 60,
            finalEstimateMinutes: 60,
            actualDurationMinutes: 68,
            status: .completed,
            createdAt: Date().addingTimeInterval(-86400 * 3),
            completedAt: Date().addingTimeInterval(-86400 * 3 + 4080),
            notes: ""
        ),
        TimeFlowTask(
            id: UUID(),
            title: "Commute to university",
            category: .transportation,
            userEstimateMinutes: 25,
            aiSuggestedMinutes: 35,
            finalEstimateMinutes: 35,
            actualDurationMinutes: 38,
            status: .completed,
            createdAt: Date().addingTimeInterval(-86400 * 2),
            completedAt: Date().addingTimeInterval(-86400 * 2 + 2280),
            notes: ""
        ),
        TimeFlowTask(
            id: UUID(),
            title: "Grocery shopping",
            category: .grocery,
            userEstimateMinutes: 30,
            aiSuggestedMinutes: 45,
            finalEstimateMinutes: 45,
            actualDurationMinutes: 50,
            status: .completed,
            createdAt: Date().addingTimeInterval(-86400 * 2),
            completedAt: Date().addingTimeInterval(-86400 * 2 + 3000),
            notes: ""
        ),
        TimeFlowTask(
            id: UUID(),
            title: "Organize project notes",
            category: .workOrganization,
            userEstimateMinutes: 40,
            aiSuggestedMinutes: 55,
            finalEstimateMinutes: 48,
            actualDurationMinutes: 52,
            status: .completed,
            createdAt: Date().addingTimeInterval(-86400),
            completedAt: Date().addingTimeInterval(-86400 + 3120),
            notes: ""
        ),
        TimeFlowTask(
            id: UUID(),
            title: "Gym session",
            category: .exercise,
            userEstimateMinutes: 70,
            aiSuggestedMinutes: 75,
            finalEstimateMinutes: 70,
            actualDurationMinutes: 73,
            status: .completed,
            createdAt: Date().addingTimeInterval(-86400),
            completedAt: Date().addingTimeInterval(-86400 + 4380),
            notes: ""
        )
    ]

    static let insights: [Insight] = [
        Insight(
            title: "Weekly Accuracy",
            message: "Your estimates are 18% more accurate than last week. Keep building this habit!",
            icon: "chart.line.uptrend.xyaxis",
            type: .improvement
        ),
        Insight(
            title: "Study Tasks",
            message: "You consistently underestimate study tasks by 25–35%. Consider adding a 30% buffer to your study estimates.",
            icon: "book.fill",
            type: .pattern
        ),
        Insight(
            title: "Transportation",
            message: "Transportation tasks are your hardest to predict. You underestimate by an average of 35%.",
            icon: "car.fill",
            type: .pattern
        ),
        Insight(
            title: "Best Category",
            message: "You estimate exercise tasks most accurately — only 4% off on average. Great self-awareness!",
            icon: "figure.run",
            type: .accuracy
        ),
        Insight(
            title: "Recommendation",
            message: "For grocery shopping, add 20–25 minutes to your first estimate. Browsing and queues add up.",
            icon: "lightbulb.fill",
            type: .recommendation
        ),
        Insight(
            title: "AI Learning Note",
            message: "TimeFlow learns from your completed tasks and adjusts suggestions over time. The more tasks you complete, the better the suggestions.",
            icon: "cpu",
            type: .aiNote
        )
    ]
}
