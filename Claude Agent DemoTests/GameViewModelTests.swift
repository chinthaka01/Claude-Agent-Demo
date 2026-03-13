import Testing
import Foundation
import SwiftUI
@testable import Claude_Agent_Demo

/// Unit tests for ``GameViewModel``, covering game state management,
/// arrow mechanics, collision detection, and scoring.
struct GameViewModelTests {

    // MARK: - Game State

    /// Verifies that starting a new game resets all counters and flags to their initial values.
    @Test @MainActor
    func startGameResetsState() {
        let viewModel = GameViewModel()
        viewModel.score = 100
        viewModel.balloonsMissed = 5
        viewModel.balloonsPopped = 3

        viewModel.startGame()

        #expect(viewModel.score == 0)
        #expect(viewModel.balloonsMissed == 0)
        #expect(viewModel.balloonsPopped == 0)
        #expect(viewModel.isGameActive)
        #expect(!viewModel.isGameOver)
        #expect(viewModel.balloons.isEmpty)
        #expect(viewModel.popEffects.isEmpty)
    }

    /// Confirms that the game ends when the missed balloon count reaches the maximum.
    @Test @MainActor
    func gameOverWhenMaxBalloonsMissed() {
        let viewModel = GameViewModel()
        viewModel.startGame()
        viewModel.balloonsMissed = viewModel.maxMissedBalloons

        // Trigger game loop to detect game over.
        viewModel.update(at: Date())
        viewModel.update(at: Date().addingTimeInterval(0.016))

        #expect(viewModel.isGameOver)
        #expect(!viewModel.isGameActive)
    }

    // MARK: - Arrow Mechanics

    /// Tests the full aim-then-fire flow: aiming stores the angle and releasing transitions to flying.
    @Test @MainActor
    func arrowAimingAndFiring() {
        let viewModel = GameViewModel()
        viewModel.startGame()

        viewModel.aimArrow(angle: 0.5)
        guard case .aiming(let angle) = viewModel.arrow.state else {
            Issue.record("Expected aiming state")
            return
        }
        #expect(angle == 0.5)

        viewModel.releaseArrow()
        guard case .flying = viewModel.arrow.state else {
            Issue.record("Expected flying state")
            return
        }
    }

    /// Ensures that attempting to aim while the arrow is already in flight is ignored.
    @Test @MainActor
    func arrowCannotAimWhileFlying() {
        let viewModel = GameViewModel()
        viewModel.startGame()

        viewModel.aimArrow(angle: 0.3)
        viewModel.releaseArrow()

        // Try to aim again while arrow is flying — should be ignored.
        viewModel.aimArrow(angle: 0.5)
        guard case .flying = viewModel.arrow.state else {
            Issue.record("Arrow state should still be flying")
            return
        }
    }

    // MARK: - Collision Detection

    /// Verifies that a flying arrow hitting a balloon awards the correct score,
    /// increments the popped count, removes the balloon, and creates a pop effect.
    @Test @MainActor
    func collisionDetection() {
        let viewModel = GameViewModel()
        viewModel.startGame()

        let balloon = Balloon(
            id: .init(),
            balloonColor: .red,
            x: 0.5,
            y: 0.5,
            fallSpeed: 0.1,
            swayAmplitude: 0,
            swayFrequency: 0,
            swayPhase: 0,
            originX: 0.5,
            radius: 0.04,
            isAlive: true,
            creationDate: Date()
        )
        viewModel.balloons.append(balloon)

        // Place the arrow tip right on the balloon.
        viewModel.arrow.state = .flying(x: 0.5, y: 0.5, angle: 0)

        let now = Date()
        viewModel.update(at: now)
        viewModel.update(at: now.addingTimeInterval(0.016))

        #expect(viewModel.score == BalloonColor.red.points)
        #expect(viewModel.balloonsPopped == 1)
        // The original balloon should be removed; new ones may have spawned.
        #expect(!viewModel.balloons.contains(where: { $0.id == balloon.id }))
        #expect(!viewModel.popEffects.isEmpty)
    }

    /// Confirms the arrow returns to idle state after successfully hitting a balloon.
    @Test @MainActor
    func arrowResetsToIdleAfterHit() {
        let viewModel = GameViewModel()
        viewModel.startGame()

        let balloon = Balloon(
            id: .init(),
            balloonColor: .blue,
            x: 0.5,
            y: 0.5,
            fallSpeed: 0.1,
            swayAmplitude: 0,
            swayFrequency: 0,
            swayPhase: 0,
            originX: 0.5,
            radius: 0.04,
            isAlive: true,
            creationDate: Date()
        )
        viewModel.balloons.append(balloon)
        viewModel.arrow.state = .flying(x: 0.5, y: 0.5, angle: 0)

        viewModel.update(at: Date())
        viewModel.update(at: Date().addingTimeInterval(0.016))

        guard case .idle = viewModel.arrow.state else {
            Issue.record("Arrow should be idle after hitting a balloon")
            return
        }
    }

    // MARK: - Aim Calculation

    /// Verifies that the aim angle is clamped to the ±60° range regardless of drag position.
    @Test @MainActor
    func angleFromDragClampedToRange() {
        let viewModel = GameViewModel()
        viewModel.startGame()

        let canvasSize = CGSize(width: 400, height: 800)

        // Drag far to the right — should be clamped to pi/3.
        let farRightAngle = viewModel.angleFromDrag(
            dragLocation: CGPoint(x: 400, y: 0),
            canvasSize: canvasSize
        )
        #expect(farRightAngle <= Double.pi / 3 + 0.001)

        // Drag far to the left — should be clamped to -pi/3.
        let farLeftAngle = viewModel.angleFromDrag(
            dragLocation: CGPoint(x: 0, y: 0),
            canvasSize: canvasSize
        )
        #expect(farLeftAngle >= -Double.pi / 3 - 0.001)
    }

    /// Confirms that cancelling an aim returns the arrow to idle without firing.
    @Test @MainActor
    func cancelAimReturnsToIdle() {
        let viewModel = GameViewModel()
        viewModel.startGame()

        viewModel.aimArrow(angle: 0.3)
        viewModel.cancelAim()

        guard case .idle = viewModel.arrow.state else {
            Issue.record("Arrow should be idle after cancelling aim")
            return
        }
    }

    // MARK: - Scoring

    /// Validates that each balloon color returns its expected point value.
    @Test
    func balloonColorPointValues() {
        #expect(BalloonColor.red.points == 10)
        #expect(BalloonColor.blue.points == 15)
        #expect(BalloonColor.green.points == 20)
        #expect(BalloonColor.yellow.points == 25)
        #expect(BalloonColor.orange.points == 30)
        #expect(BalloonColor.purple.points == 50)
    }

    // MARK: - Difficulty

    /// Verifies that starting a game sets the chosen difficulty on the view model.
    @Test @MainActor
    func startGameSetsDifficulty() {
        let viewModel = GameViewModel()

        viewModel.startGame(difficulty: .easy)
        #expect(viewModel.difficulty == .easy)

        viewModel.startGame(difficulty: .hard)
        #expect(viewModel.difficulty == .hard)
    }

    /// Verifies that starting a game without specifying difficulty defaults to medium.
    @Test @MainActor
    func startGameDefaultsToMediumDifficulty() {
        let viewModel = GameViewModel()
        viewModel.startGame()
        #expect(viewModel.difficulty == .medium)
    }

    /// Verifies that each difficulty level has the expected speed multiplier.
    @Test
    func difficultySpeedMultipliers() {
        #expect(Difficulty.easy.speedMultiplier == 0.6)
        #expect(Difficulty.medium.speedMultiplier == 1.0)
        #expect(Difficulty.hard.speedMultiplier == 1.6)
    }
}
