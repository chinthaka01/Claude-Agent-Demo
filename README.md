# Balloon Pop

An iOS arcade game built with SwiftUI where players shoot arrows to pop falling balloons.

## Gameplay

- **Drag to aim** an arrow from the bow at the bottom of the screen
- **Release to fire** the arrow upward at falling balloons
- Each balloon color has a different point value — purple balloons are worth the most (50 pts)
- The game ends after **15 missed balloons**

### Balloon Point Values

| Color  | Points |
|--------|--------|
| Red    | 10     |
| Blue   | 15     |
| Green  | 20     |
| Yellow | 25     |
| Orange | 30     |
| Purple | 50     |

## Architecture

- **SwiftUI** with `Canvas` for high-performance rendering
- **`@Observable`** view model for game state and logic
- **TimelineView** driving a per-frame game loop
- Normalized coordinate system (0–1) for screen-independent layout
- All models are `Sendable` for strict Swift 6 concurrency

### Project Structure

```
Game/
├── Arrow.swift            # Arrow model and state machine
├── Balloon.swift          # Balloon model with sway physics
├── BalloonColor.swift     # Color enum with point values
├── GameCanvasView.swift   # Canvas-based rendering and input
├── GameOverView.swift     # End-of-game summary screen
├── GameView.swift         # Top-level game container
├── GameViewModel.swift    # Core game logic and state
├── PopEffect.swift        # Burst particle animation
├── ScoreOverlayView.swift # Live score HUD
└── StartScreenView.swift  # Welcome / start screen
```

## Requirements

- iOS 26.0+
- Xcode 26+
- Swift 6.2+

## Testing

Unit tests for core game logic are in `GameViewModelTests.swift`, covering state management, collision detection, arrow mechanics, and scoring. Run them with **Cmd+U** in Xcode or:

```
xcodebuild test -scheme "Claude Agent Demo" -destination "platform=iOS Simulator,name=iPhone"
```
