import SwiftUI

/// A burst particle effect shown when a balloon is popped.
struct PopEffect: Identifiable, Sendable {
    let id: UUID
    /// Normalized X position of the burst center.
    let x: Double
    /// Normalized Y position of the burst center.
    let y: Double
    /// The color of the particles.
    let color: Color
    /// When the effect was created.
    let creationDate: Date

    /// How long the burst animation lasts in seconds.
    static let duration: TimeInterval = 0.4

    /// Returns the animation progress (0...1) at the given date.
    func progress(at date: Date) -> Double {
        min(1.0, date.timeIntervalSince(creationDate) / Self.duration)
    }
}
