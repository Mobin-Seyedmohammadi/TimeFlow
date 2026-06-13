import SwiftUI

// MARK: - Color Palette
extension Color {
    // Backgrounds
    static let tfBackground = Color(hex: "F6EEE3")

    // Brand
    static let tfBlue = Color(hex: "2B00FF")
    static let tfOrange = Color(hex: "FF4200")

    // Gradient palette
    static let gradLavender = Color(hex: "C8BFDF")
    static let gradPeach = Color(hex: "E8C4B0")
    static let gradBlush = Color(hex: "F2D4CC")
    static let gradMauve = Color(hex: "D4B8C8")
    static let gradCream = Color(hex: "F6EEE3")
    static let gradMint = Color(hex: "BFD9D4")
    static let gradSky = Color(hex: "BFD0E8")

    // Text
    static let tfDark = Color.black
    static let tfSecondary = Color(hex: "6B6B6B")

    // Glass
    static let glassWhite = Color.white.opacity(0.55)
    static let glassBorder = Color.white.opacity(0.35)

    // Legacy alias kept for backwards compat
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
        case .study:            return "book.fill"
        case .transportation:   return "car.fill"
        case .grocery:          return "cart.fill"
        case .workOrganization: return "briefcase.fill"
        case .exercise:         return "figure.run"
        case .home:             return "house.fill"
        case .other:            return "square.grid.2x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .study:            return .tfBlue
        case .transportation:   return Color(hex: "7C3AED")
        case .grocery:          return Color(hex: "059669")
        case .workOrganization: return Color(hex: "D97706")
        case .exercise:         return Color(hex: "DC2626")
        case .home:             return Color(hex: "2563EB")
        case .other:            return Color(hex: "6B7280")
        }
    }

    /// Used ONLY when n == 0 (no personal history). Never used when personal history exists.
    var defaultAdjustmentFactor: Double {
        switch self {
        case .study:            return 1.30
        case .transportation:   return 1.28
        case .grocery:          return 1.25
        case .workOrganization: return 1.20
        case .exercise:         return 1.08
        case .home:             return 1.15
        case .other:            return 1.15
        }
    }
}

// MARK: - RegressionStats
/// Stores sufficient statistics for online linear regression.
/// x = userEstimateMinutes, y = actualDurationMinutes
struct RegressionStats: Codable {
    var n: Double = 0
    var sumX: Double = 0
    var sumY: Double = 0
    var sumXX: Double = 0
    var sumXY: Double = 0
    var sumYY: Double = 0

    mutating func update(x: Double, y: Double) {
        n += 1
        sumX += x
        sumY += y
        sumXX += x * x
        sumXY += x * y
        sumYY += y * y
    }
}

// MARK: - PredictionConfidence
enum PredictionConfidence {
    case none       // n == 0
    case veryLow    // n == 1
    case low        // n == 2
    case medium     // n 3–5
    case high       // n 6–9
    case veryHigh   // n >= 10
}

// MARK: - PredictionResult
struct PredictionResult {
    let pointEstimate: Int        // always >= 1
    let lowBound: Int             // always >= 1
    let highBound: Int            // always > lowBound
    let confidencePercent: Int    // e.g. 80, 85, 90, 95 — from user setting
    let confidence: PredictionConfidence
    let explanation: String
    let dataSource: String
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
        case .draft:     return "pencil.circle"
        case .ready:     return "play.circle"
        case .active:    return "timer"
        case .paused:    return "pause.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .overtime:  return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .draft:     return .secondary
        case .ready:     return .tfBlue
        case .active:    return .tfBlue
        case .paused:    return Color(hex: "D97706")
        case .completed: return Color(hex: "059669")
        case .overtime:  return .tfOrange
        }
    }
}

// MARK: - WarningState
enum WarningState: String, Codable {
    case none
    case nearLimit
    case reachedLimit
    case overtime
}

// MARK: - ActiveTaskSession
/// Bundles all per-task timer state so multiple tasks can run concurrently.
struct ActiveTaskSession: Identifiable, Codable {
    var task: TimeFlowTask
    /// Wall-clock anchor stored as epoch. nil when paused.
    var taskStartEpoch: Double?
    var elapsedMinutes: Double
    var isRunning: Bool
    var warningState: WarningState
    var continuedAfterWarning: Bool
    var hasShownNearLimit: Bool
    var hasShownReachedLimit: Bool
    var warningBannerDismissed: Bool

    var id: UUID { task.id }

    var overtimeMinutes: Double {
        max(0, elapsedMinutes - Double(task.finalEstimateMinutes))
    }
    var remainingMinutes: Double {
        max(0, Double(task.finalEstimateMinutes) - elapsedMinutes)
    }
    var progressFraction: Double {
        guard task.finalEstimateMinutes > 0 else { return 0 }
        return min(elapsedMinutes / Double(task.finalEstimateMinutes), 1.0)
    }
    var isActuallyOvertime: Bool {
        elapsedMinutes >= Double(task.finalEstimateMinutes)
    }
}

// MARK: - AIConfidence
enum AIConfidence: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var color: Color {
        switch self {
        case .low:    return .secondary
        case .medium: return Color(hex: "D97706")
        case .high:   return Color(hex: "059669")
        }
    }
}

// MARK: - AISuggestion
struct AISuggestion: Equatable {
    let suggestedMinutes: Int
    let lowBound: Int
    let highBound: Int
    let confidencePercent: Int
    let confidence: AIConfidence
    let explanation: String
    let dataSource: String
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
