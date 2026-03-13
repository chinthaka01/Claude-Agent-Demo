import SwiftUI

/// Core game logic for the balloon-popping arrow game.
///
/// Manages the game loop, balloon spawning, arrow flight, collision detection,
/// score tracking, and game-over conditions. All coordinates are normalized
/// (0...1) so the view layer can scale them to any screen size.
@Observable
@MainActor
final class GameViewModel {

    // MARK: - Game State

    /// All balloons currently on screen (alive or recently popped).
    var balloons: [Balloon] = []

    /// The player's arrow, centered horizontally and starting in idle state.
    var arrow = Arrow(baseX: 0.5, state: .idle, flightSpeed: 1.8, length: 0.06)

    /// Active pop particle effects waiting to finish their animation.
    var popEffects: [PopEffect] = []

    /// The player's running score, accumulated from popping balloons.
    var score: Int = 0

    /// Whether the game has ended (missed balloon limit reached).
    var isGameOver: Bool = false

    /// Whether the game is currently in play (balloons spawning, arrow usable).
    var isGameActive: Bool = false

    /// Total number of balloons the player has popped this round.
    var balloonsPopped: Int = 0

    /// Number of balloons that fell off the bottom without being popped.
    var balloonsMissed: Int = 0

    /// The current difficulty level, controlling balloon fall speed.
    var difficulty: Difficulty = .medium

    // MARK: - Configuration

    /// The game ends when this many balloons escape unpopped.
    let maxMissedBalloons = 15

    /// Minimum time between consecutive balloon spawns.
    private let balloonSpawnInterval: TimeInterval = 0.8

    /// Normalized radius of each balloon relative to screen width.
    private let balloonRadius: Double = 0.04

    /// Normalized Y position of the bow (near the bottom of the screen).
    let bowY: Double = 0.92

    // MARK: - Internal Tracking

    /// Timestamp of the last game-loop update, used to compute delta time.
    private var lastUpdateDate: Date?

    /// Timestamp of the last balloon spawn, used to enforce the spawn interval.
    private var lastSpawnDate: Date = .distantPast

    // MARK: - Game Loop

    /// Called every frame by the TimelineView to advance the game state.
    func update(at date: Date) {
        guard isGameActive, !isGameOver else { return }

        let deltaTime: TimeInterval
        if let last = lastUpdateDate {
            deltaTime = date.timeIntervalSince(last)
        } else {
            deltaTime = 0
        }
        lastUpdateDate = date

        // Skip unreasonable deltas (e.g. app returning from background).
        guard deltaTime > 0, deltaTime < 1.0 else { return }

        spawnBalloonsIfNeeded(at: date)
        updateBalloons(deltaTime: deltaTime, currentDate: date)
        updateArrow(deltaTime: deltaTime)
        checkCollisions(at: date)
        cleanUp(at: date)
        checkGameOver()
    }

    // MARK: - Spawning

    /// Spawns a new balloon at a random horizontal position if enough time
    /// has elapsed since the last spawn.
    private func spawnBalloonsIfNeeded(at date: Date) {
        guard date.timeIntervalSince(lastSpawnDate) >= balloonSpawnInterval else { return }
        lastSpawnDate = date

        let xPosition = Double.random(in: 0.1...0.9)
        let baseFallSpeed = Double.random(in: 0.08...0.18)
        let balloon = Balloon(
            id: UUID(),
            balloonColor: BalloonColor.allCases.randomElement() ?? .red,
            x: xPosition,
            y: -0.05,
            fallSpeed: baseFallSpeed * difficulty.speedMultiplier,
            swayAmplitude: Double.random(in: 0.02...0.06),
            swayFrequency: Double.random(in: 1.5...3.0),
            swayPhase: Double.random(in: 0...(2 * .pi)),
            originX: xPosition,
            radius: balloonRadius,
            isAlive: true,
            creationDate: date
        )
        balloons.append(balloon)
    }

    // MARK: - Movement

    /// Advances each balloon downward and applies sinusoidal horizontal sway.
    /// Balloons that fall off-screen are counted as missed and removed.
    private func updateBalloons(deltaTime: TimeInterval, currentDate: Date) {
        for index in balloons.indices {
            balloons[index].y += balloons[index].fallSpeed * deltaTime

            // Horizontal sway using a sine wave.
            let elapsed = currentDate.timeIntervalSince(balloons[index].creationDate)
            let sway = balloons[index].swayAmplitude
                * sin(balloons[index].swayFrequency * elapsed + balloons[index].swayPhase)
            balloons[index].x = balloons[index].originX + sway
        }

        // Count balloons that fell off screen while still alive.
        let escaped = balloons.filter { $0.y > 1.1 && $0.isAlive }
        balloonsMissed += escaped.count
        balloons.removeAll { $0.y > 1.1 }
    }

    /// Moves the arrow along its flight trajectory. Resets to idle if it
    /// leaves the visible bounds.
    private func updateArrow(deltaTime: TimeInterval) {
        guard case .flying(var x, var y, let angle) = arrow.state else { return }

        x += sin(angle) * arrow.flightSpeed * deltaTime
        y -= cos(angle) * arrow.flightSpeed * deltaTime

        if y < -0.1 || x < -0.1 || x > 1.1 {
            arrow.state = .idle
        } else {
            arrow.state = .flying(x: x, y: y, angle: angle)
        }
    }

    // MARK: - Collision Detection

    /// Tests the arrow tip position against every alive balloon. On a hit,
    /// the balloon is marked dead, the score is updated, a pop effect is
    /// created, and the arrow resets to idle. Only one balloon is hit per arrow.
    private func checkCollisions(at date: Date) {
        guard case .flying(let ax, let ay, _) = arrow.state else { return }

        for index in balloons.indices where balloons[index].isAlive {
            let dx = ax - balloons[index].x
            let dy = ay - balloons[index].y
            let distance = sqrt(dx * dx + dy * dy)

            if distance < balloons[index].radius {
                balloons[index].isAlive = false
                score += balloons[index].balloonColor.points
                balloonsPopped += 1
                arrow.state = .idle

                popEffects.append(PopEffect(
                    id: UUID(),
                    x: balloons[index].x,
                    y: balloons[index].y,
                    color: balloons[index].balloonColor.color,
                    creationDate: date
                ))

                // Arrow hits only one balloon at a time.
                return
            }
        }
    }

    // MARK: - User Input

    /// Begin aiming the arrow at the given angle.
    func aimArrow(angle: Double) {
        guard case .idle = arrow.state else { return }
        arrow.state = .aiming(angle: angle)
    }

    /// Update the aim angle while dragging.
    func updateAim(angle: Double) {
        if case .aiming = arrow.state {
            arrow.state = .aiming(angle: angle)
        }
    }

    /// Release the arrow, firing it in the current aim direction.
    func releaseArrow() {
        guard case .aiming(let angle) = arrow.state else { return }
        arrow.state = .flying(
            x: arrow.baseX + sin(angle) * 0.02,
            y: bowY,
            angle: angle
        )
    }

    /// Cancel the current aim and return the arrow to idle.
    func cancelAim() {
        if case .aiming = arrow.state {
            arrow.state = .idle
        }
    }

    /// Calculate the aim angle from a drag gesture location.
    /// Returns an angle in radians from vertical, clamped to ±60°.
    func angleFromDrag(dragLocation: CGPoint, canvasSize: CGSize) -> Double {
        let normalizedDragX = dragLocation.x / canvasSize.width
        let normalizedDragY = dragLocation.y / canvasSize.height

        let dx = normalizedDragX - arrow.baseX
        let dy = bowY - normalizedDragY

        guard dy > 0.01 else { return 0 }

        let angle = atan2(dx, dy)
        return max(-.pi / 3, min(.pi / 3, angle))
    }

    // MARK: - Cleanup

    /// Removes expired pop effects and dead balloons from their arrays.
    private func cleanUp(at date: Date) {
        popEffects.removeAll { date.timeIntervalSince($0.creationDate) > PopEffect.duration }
        balloons.removeAll { !$0.isAlive }
    }

    /// Ends the game if the player has missed the maximum allowed number of balloons.
    private func checkGameOver() {
        if balloonsMissed >= maxMissedBalloons {
            isGameOver = true
            isGameActive = false
        }
    }

    // MARK: - Game Control

    /// Start or restart the game with the given difficulty level.
    /// - Parameter difficulty: The difficulty to use for this round. Defaults to `.medium`.
    func startGame(difficulty: Difficulty = .medium) {
        self.difficulty = difficulty
        balloons.removeAll()
        popEffects.removeAll()
        arrow.state = .idle
        score = 0
        balloonsPopped = 0
        balloonsMissed = 0
        isGameOver = false
        isGameActive = true
        lastUpdateDate = nil
        lastSpawnDate = .distantPast
    }
}
