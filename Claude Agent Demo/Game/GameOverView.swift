import SwiftUI

/// Displayed when the game ends, showing the final score and a restart button.
///
/// Presents a translucent card with the player's score, the number of
/// balloons popped, and a "Play Again" button that invokes the `onRestart` closure.
struct GameOverView: View {
    /// The player's final score.
    let score: Int

    /// Total number of balloons the player popped during the game.
    let balloonsPopped: Int

    /// Called when the player taps "Play Again" to reset and start a new game.
    let onRestart: () -> Void

    var body: some View {
        VStack {
            Text("Game Over")
                .font(.largeTitle)
                .bold()

            // Display score with locale-aware number formatting.
            Text(score, format: .number)
                .font(.system(.title, design: .rounded))
                .bold()

            Text("Balloons Popped: \(balloonsPopped)")
                .font(.headline)

            Button("Play Again", systemImage: "arrow.counterclockwise") {
                onRestart()
            }
            .buttonStyle(.borderedProminent)
        }
        .foregroundStyle(.white)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 20))
    }
}
