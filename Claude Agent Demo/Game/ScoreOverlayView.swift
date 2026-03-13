import SwiftUI

/// HUD overlay pinned to the top of the screen during active gameplay.
///
/// Displays the player's current score and balloons popped on the left,
/// and a missed-balloon counter on the right. The missed counter turns
/// red once the player has missed more than half the allowed maximum,
/// providing a visual warning that the game is nearing its end.
struct ScoreOverlayView: View {
    /// The player's running score.
    let score: Int

    /// Number of balloons that have fallen off-screen without being popped.
    let balloonsMissed: Int

    /// The maximum number of missed balloons before the game ends.
    let maxMissedBalloons: Int

    /// Total number of balloons popped so far.
    let balloonsPopped: Int

    var body: some View {
        HStack {
            // Left column: score and pop count.
            VStack(alignment: .leading) {
                Text("Score: \(score)")
                    .font(.title2)
                    .bold()
                Text("Popped: \(balloonsPopped)")
                    .font(.caption)
            }

            Spacer()

            // Right column: missed counter with color warning.
            VStack(alignment: .trailing) {
                Text("Missed: \(balloonsMissed)/\(maxMissedBalloons)")
                    .font(.caption)
                    .foregroundStyle(balloonsMissed > maxMissedBalloons / 2 ? .red : .secondary)
            }
        }
        .padding()
        .foregroundStyle(.white)
    }
}
