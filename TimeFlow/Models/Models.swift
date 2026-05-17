import SwiftUI

// MARK: - Color Palette
extension Color {
    static let tfBackground = Color(hex: "F6EEE3")
    static let tfDark = Color.black
    static let tfBlue = Color(hex: "2B00FF")
    static let tfOrange = Color(hex: "FF4200")
    static let tfCard = Color.white

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - TaskCategory
enum TaskCategory: String, CaseIterable, Codable, Identifiable {
    case study = "Study"
    case transportation = "Transportation"
    case grocery = "Grocery Shopping"
    case workOrganization = "Work / Organization"
    case exercise = "Exercise"
    case home = "Home Tasks"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .study: return "book.fill"
        case .transportation: return "car.fill"
        case .grocery: return "cart.fill"
        case .workOrganization: return "briefcase.fill"
        case .exercise: return "figure.run"
        case .home: return "house.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .study: return .tfBlue
        case .transportation: return Color(hex: "7C3AED")
        case .grocery: return Color(hex: "059669")
        case .workOrganization: return Color(hex: "D97706")
        case .exercise: return Color(hex: "DC2626")
        case .home: return Color(hex: "2563EB")
        case .other: return Color(hex: "6B7280")
        }
    }

    var aiAdjustmentFactor: Double {
        switch self {
        case .study: return 1.30
        case .transportation: return 1.35
        case .grocery: return 1.25
        case .workOrganization: return 1.20
        case .exercise: return 1.05
        case .home: return 1.15
        case .other: return 1.15
        }
    }
}

// MARK: - TaskStatus
enum TaskStatus: String, Codable {
    case draft = "Draft"
    case ready = "Ready"
    case active = "Active"
    case paused = "Paused"
    case completed = "Completed"
    case overtime = "Overtime"

    var icon: String {
        switch self {
        case .draft: return "pencil.circle"
        case .ready: return "play.circle"
        case .active: return "timer"
        case .paused: return "pause.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .overtime: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .draft: return .secondary
        case .ready: return .tfBlue
        case .active: return .tfBlue
        case .paused: return Color(hex: "D97706")
        case .completed: return Color(hex: "059669")
        case .overtime: return .tfOrange
        }
    }
}

// MARK: - WarningState
enum WarningState {
    case none
    case nearLimit
    case reachedLimit
    case overtime
}

// MARK: - AIConfidence
enum AIConfidence: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var color: Color {
        switch self {
        case .low: return .secondary
        case .medium: return Color(hex: "D97706")
        case .high: return Color(hex: "059669")
        }
    }
}

// MARK: - AISuggestion
struct AISuggestion: Equatable {
    let suggestedMinutes: Int
    let confidence: AIConfidence
    let explanation: String
}

// MARK: - TimeFlowTask
struct TimeFlowTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var category: TaskCategory
    var userEstimateMinutes: Int
    var aiSuggestedMinutes: Int
    var finalEstimateMinutes: Int
    var actualDurationMinutes: Int?
    var status: TaskStatus
    var createdAt: Date
    var completedAt: Date?
    var notes: String

    var estimationDifferenceMinutes: Int? {
        guard let actual = actualDurationMinutes else { return nil }
        return actual - finalEstimateMinutes
    }

    var estimationLabel: String {
        guard let diff = estimationDifferenceMinutes else { return "Pending" }
        if abs(diff) <= 3 { return "Accurate" }
        return diff > 0 ? "Underestimated" : "Overestimated"
    }

    var estimationLabelColor: Color {
        guard let diff = estimationDifferenceMinutes else { return .secondary }
        if abs(diff) <= 3 { return Color(hex: "059669") }
        return diff > 0 ? .tfOrange : Color(hex: "2563EB")
    }

    var accuracyPercentage: Double? {
        guard let actual = actualDurationMinutes, finalEstimateMinutes > 0 else { return nil }
        return Double(actual) / Double(finalEstimateMinutes)
    }
}

// MARK: - Insight
struct Insight: Identifiable {
    var id: UUID = UUID()
    var title: String
    var message: String
    var icon: String
    var type: InsightType
}

// Swift auto-synthesizes Equatable for enums with no associated values
enum InsightType: Equatable {
    case accuracy, pattern, recommendation, improvement, aiNote
}
