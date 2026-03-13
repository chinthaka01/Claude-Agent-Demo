import Foundation

/// The possible states of the player's arrow.
enum ArrowState: Sendable {
    /// Resting at the bow, ready to aim.
    case idle
    /// Being aimed at the given angle (radians from vertical, positive = right).
    case aiming(angle: Double)
    /// In flight at the given normalized position and direction angle.
    case flying(x: Double, y: Double, angle: Double)
}

/// The player's arrow, fired from the bow at the bottom of the screen.
/// All positions use normalized coordinates (0...1).
struct Arrow: Sendable {
    /// Normalized X position of the bow (0...1).
    var baseX: Double

    /// Current state of the arrow.
    var state: ArrowState

    /// Flight speed in normalized units per second.
    let flightSpeed: Double

    /// Normalized length of the arrow relative to screen height.
    let length: Double
}
