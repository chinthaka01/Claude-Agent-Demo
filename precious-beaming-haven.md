# Balloon Pop Arrow Game - Implementation Plan

## Overview
A SwiftUI game where colorful balloons fall from the top of the screen and the player aims and shoots arrows from a bow at the bottom to pop them. Uses `Canvas` + `TimelineView` for performant rendering.

## Architecture
- **Rendering**: `Canvas` inside `TimelineView(.animation)` for 60fps game loop
- **State**: `@Observable @MainActor` view model owns all game state
- **Coordinates**: Normalized (0.0–1.0) in the model, scaled to pixels at render time
- **Input**: `DragGesture` to aim the arrow (direction based on drag position relative to bow), release to fire

## Files to Create

### Model Layer (`Game/` group)
1. **`BalloonColor.swift`** — Enum of balloon colors (red, blue, green, yellow, orange, purple) with SwiftUI `Color` and point values
2. **`Balloon.swift`** — Struct with position, fall speed, horizontal sway parameters, radius, alive state
3. **`Arrow.swift`** — Struct with state enum (idle/aiming/flying), base position, flight speed
4. **`PopEffect.swift`** — Burst particle effect model for popped balloons

### View Model
5. **`GameViewModel.swift`** — `@Observable @MainActor` class containing:
   - Game loop (`update(at:)`) — spawn, move, collide, cleanup
   - Balloon spawning at random intervals and positions
   - Arrow aiming/firing logic with angle clamping (±60°)
   - Circle-based collision detection (arrow tip vs balloon center)
   - Score tracking, missed balloon counting, game over detection (15 missed = game over)

### Views
6. **`GameCanvasView.swift`** — `Canvas` renderer drawing balloons (colored ovals with highlights and strings), arrow, bow, aim guideline, pop particles. `DragGesture` for aiming. Uses `.onGeometryChange` for size tracking (not `GeometryReader`). Uses `.onChange(of: timeline.date)` to drive game loop updates separately from rendering.
7. **`ScoreOverlayView.swift`** — HUD showing score, popped count, missed count
8. **`GameOverView.swift`** — Game over card with score and "Play Again" button
9. **`StartScreenView.swift`** — Title and "Start Game" button
10. **`GameView.swift`** — Composition root: owns `@State var viewModel`, layers `GameCanvasView` + overlay views in a `ZStack`

### Existing File Changes
11. **`ContentView.swift`** — Replace body with `GameView()`

### Tests
12. **`GameViewModelTests.swift`** (in test target) — Tests for: start/reset, game over condition, aiming/firing, collision detection, point scoring

## Game Mechanics
- Balloons spawn every ~0.8s at random X positions above the screen, fall at varying speeds with sine-wave horizontal sway
- Arrow fires in a straight line from the bow; resets to idle on hit or screen exit
- Only one arrow in flight at a time; aiming disabled while arrow is flying
- Each color awards different points (red=10, purple=50)
- Game ends after 15 missed balloons

## Verification
1. Build project with `BuildProject`
2. Render previews with `RenderPreview` on `GameView`
3. Run unit tests with `RunSomeTests` on `GameViewModelTests`
