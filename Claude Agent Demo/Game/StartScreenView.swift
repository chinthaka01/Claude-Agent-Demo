import SwiftUI

/// Initial screen shown before the first game and after returning from game over.
///
/// Displays the game title, a brief instruction, and a prominent "Start Game" button.
struct StartScreenView: View {
    /// Called when the player taps "Start Game" to begin a new round.
    let onStart: () -> Void

    var body: some View {
        VStack {
            Text("Balloon Pop")
                .font(.largeTitle)
                .bold()

            Text("Aim and shoot arrows to pop balloons!")
                .font(.subheadline)

            Button("Start Game", systemImage: "play.fill") {
                onStart()
            }
            .buttonStyle(.borderedProminent)
        }
        .foregroundStyle(.white)
    }
}
