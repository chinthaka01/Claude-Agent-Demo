import SwiftUI

/// The different colors a balloon can have, each with its own point value.
enum BalloonColor: CaseIterable, Sendable {
    case red, blue, green, yellow, orange, purple

    /// The SwiftUI color used to render the balloon.
    var color: Color {
        switch self {
        case .red: .red
        case .blue: .blue
        case .green: .green
        case .yellow: .yellow
        case .orange: .orange
        case .purple: .purple
        }
    }

    /// Points awarded for popping a balloon of this color.
    var points: Int {
        switch self {
        case .red: 10
        case .blue: 15
        case .green: 20
        case .yellow: 25
        case .orange: 30
        case .purple: 50
        }
    }
}
