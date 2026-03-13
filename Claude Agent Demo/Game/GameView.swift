import SwiftUI

/// Top-level game view that composes the canvas, HUD overlays, and screen states.
///
/// The view manages three visual states:
/// - **Start screen**: shown before the first game and after returning from game over.
/// - **Active gameplay**: the canvas renders balloons, the bow, and arrows while
///   the score overlay shows live stats at the top.
/// - **Game over**: a centered overlay displays the final score and a restart button.
struct GameView: View {
    @State private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            // Sky gradient background visible behind all game states.
            LinearGradient(
                colors: [
                    Color(red: 0.53, green: 0.81, blue: 0.92),
                    Color(red: 0.25, green: 0.47, blue: 0.85)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Canvas layer handles all real-time game drawing.
            GameCanvasView(viewModel: viewModel)

            // HUD / state overlays layered on top of the canvas.
            VStack {
                if viewModel.isGameActive {
                    ScoreOverlayView(
                        score: viewModel.score,
                        balloonsMissed: viewModel.balloonsMissed,
                        maxMissedBalloons: viewModel.maxMissedBalloons,
                        balloonsPopped: viewModel.balloonsPopped
                    )
                }

                Spacer()

                // Show the start screen when the game has not yet begun.
                if !viewModel.isGameActive && !viewModel.isGameOver {
                    StartScreenView {
                        viewModel.startGame()
                    }

                    Spacer()
                }

                // Show the game over screen with final results.
                if viewModel.isGameOver {
                    GameOverView(
                        score: viewModel.score,
                        balloonsPopped: viewModel.balloonsPopped
                    ) {
                        viewModel.startGame()
                    }

                    Spacer()
                }
            }
        }
    }
}

#Preview {
    GameView()
}
