import Foundation

/// A balloon that falls from the top of the screen.
/// All positions use normalized coordinates (0...1).
struct Balloon: Identifiable, Sendable {
    let id: UUID
    let balloonColor: BalloonColor

    /// Normalized X position (0 = left edge, 1 = right edge).
    var x: Double
    /// Normalized Y position (0 = top, 1 = bottom).
    var y: Double

    /// Fall speed in normalized units per second.
    let fallSpeed: Double

    /// Horizontal sway amplitude in normalized units.
    let swayAmplitude: Double
    /// Sway frequency in radians per second.
    let swayFrequency: Double
    /// Phase offset so balloons don't sway in sync.
    let swayPhase: Double

    /// The original X position used as the center of the sway oscillation.
    let originX: Double

    /// Normalized radius relative to screen width.
    let radius: Double

    /// Whether the balloon has not yet been popped.
    var isAlive: Bool

    /// Creation time, used for sway calculations.
    let creationDate: Date
}
