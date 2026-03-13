import SwiftUI

/// Initial screen shown before the first game and after returning from game over.
///
/// Displays the game title, a brief instruction, and difficulty selection buttons.
struct StartScreenView: View {
    /// Called when the player selects a difficulty to begin a new round.
    let onStart: (Difficulty) -> Void

    var body: some View {
        VStack {
            Text("Balloon Pop")
                .font(.largeTitle)
                .bold()

            Text("Aim and shoot arrows to pop balloons!")
                .font(.subheadline)

            Text("Select Difficulty")
                .font(.headline)
                .padding(.top)

            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                Button(difficulty.rawValue, systemImage: difficulty.systemImage) {
                    onStart(difficulty)
                }
                .buttonStyle(.borderedProminent)
                .tint(tintColor(for: difficulty))
            }
        }
        .foregroundStyle(.white)
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
