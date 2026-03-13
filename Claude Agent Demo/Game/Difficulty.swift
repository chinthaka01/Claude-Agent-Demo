import Foundation

/// Represents the game difficulty level, which controls how fast balloons fall.
enum Difficulty: String, CaseIterable, Sendable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    /// Multiplier applied to balloon fall speed.
    /// Higher values make balloons fall faster.
    var speedMultiplier: Double {
        switch self {
        case .easy: 0.6
        case .medium: 1.0
        case .hard: 1.6
        }
    }

    /// The SF Symbol icon associated with this difficulty level.
    var systemImage: String {
        switch self {
        case .easy: "tortoise.fill"
        case .medium: "figure.walk"
        case .hard: "hare.fill"
        }
    }
}
