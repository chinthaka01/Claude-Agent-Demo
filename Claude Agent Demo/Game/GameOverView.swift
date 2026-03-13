import SwiftUI

/// Displayed when the game ends, showing the final score and restart options.
///
/// Presents a translucent card with the player's score, the number of
/// balloons popped, and difficulty selection buttons to start a new game.
struct GameOverView: View {
    /// The player's final score.
    let score: Int

    /// Total number of balloons the player popped during the game.
    let balloonsPopped: Int

    /// The difficulty that was used for the completed game.
    let difficulty: Difficulty

    /// Called when the player selects a difficulty to restart the game.
    let onRestart: (Difficulty) -> Void

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

            Text("Play Again")
                .font(.headline)
                .padding(.top)

            ForEach(Difficulty.allCases, id: \.self) { level in
                Button(level.rawValue, systemImage: level.systemImage) {
                    onRestart(level)
                }
                .buttonStyle(.borderedProminent)
                .tint(tintColor(for: level))
            }
        }
        .foregroundStyle(.white)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 20))
    }

    /// Returns a tint color for each difficulty level.
    private func tintColor(for difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy: .green
        case .medium: .orange
        case .hard: .red
        }
    }
}
