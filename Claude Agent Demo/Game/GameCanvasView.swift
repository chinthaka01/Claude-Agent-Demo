import SwiftUI

/// The main game rendering view that draws all visual elements using `Canvas` for
/// high-performance 2D rendering. Paired with `TimelineView` to drive a frame-based
/// game loop that updates the view model each animation frame.
struct GameCanvasView: View {
    @Bindable var viewModel: GameViewModel

    /// Cached canvas dimensions, used to convert drag gestures into normalized coordinates.
    @State private var canvasSize: CGSize = .zero

    var body: some View {
        // TimelineView drives the game loop; paused when the game is not active.
        TimelineView(.animation(paused: !viewModel.isGameActive)) { timeline in
            Canvas { context, size in
                drawBackground(context: &context, size: size)
                drawBalloons(context: &context, size: size, date: timeline.date)
                drawAimLine(context: &context, size: size)
                drawArrow(context: &context, size: size)
                drawBow(context: &context, size: size)
                drawPopEffects(context: &context, size: size, date: timeline.date)
            }
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newSize in
                canvasSize = newSize
            }
            // Advance game state every frame.
            .onChange(of: timeline.date) { _, newDate in
                viewModel.update(at: newDate)
            }
        }
        .gesture(aimGesture)
        .ignoresSafeArea()
    }

    // MARK: - Gesture

    /// A drag gesture that handles aiming and firing the arrow.
    /// Touch-down begins aiming, dragging updates the aim angle,
    /// and releasing fires the arrow.
    private var aimGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let angle = viewModel.angleFromDrag(
                    dragLocation: value.location,
                    canvasSize: canvasSize
                )
                switch viewModel.arrow.state {
                case .idle:
                    viewModel.aimArrow(angle: angle)
                case .aiming:
                    viewModel.updateAim(angle: angle)
                case .flying:
                    break
                }
            }
            .onEnded { _ in
                viewModel.releaseArrow()
            }
    }

    // MARK: - Drawing

    /// Draws a sky-to-ocean gradient background with a green ground strip at the bottom.
    private func drawBackground(context: inout GraphicsContext, size: CGSize) {
        let gradient = Gradient(colors: [
            Color(red: 0.53, green: 0.81, blue: 0.92),
            Color(red: 0.25, green: 0.47, blue: 0.85)
        ])
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                gradient,
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )

        // Ground area
        let groundRect = CGRect(
            x: 0,
            y: size.height * 0.95,
            width: size.width,
            height: size.height * 0.05
        )
        context.fill(
            Path(roundedRect: groundRect, cornerSize: .zero),
            with: .color(Color(red: 0.3, green: 0.6, blue: 0.3))
        )
    }

    /// Draws all alive balloons as colored ovals with a specular highlight, string, and knot.
    private func drawBalloons(context: inout GraphicsContext, size: CGSize, date: Date) {
        for balloon in viewModel.balloons where balloon.isAlive {
            let cx = balloon.x * size.width
            let cy = balloon.y * size.height
            let r = balloon.radius * size.width

            // Balloon body — an oval slightly taller than wide.
            let balloonRect = CGRect(
                x: cx - r,
                y: cy - r * 1.3,
                width: r * 2,
                height: r * 2.6
            )
            context.fill(Path(ellipseIn: balloonRect), with: .color(balloon.balloonColor.color))

            // Highlight for a 3D effect.
            let highlightRect = CGRect(
                x: cx - r * 0.4,
                y: cy - r * 1.0,
                width: r * 0.5,
                height: r * 0.7
            )
            context.fill(
                Path(ellipseIn: highlightRect),
                with: .color(.white.opacity(0.3))
            )

            // String hanging below the balloon.
            var stringPath = Path()
            stringPath.move(to: CGPoint(x: cx, y: cy + r * 1.3))
            stringPath.addQuadCurve(
                to: CGPoint(x: cx + 3, y: cy + r * 2.0),
                control: CGPoint(x: cx - 4, y: cy + r * 1.6)
            )
            context.stroke(stringPath, with: .color(.gray), lineWidth: 1)

            // Knot at the bottom of the balloon.
            let knotRect = CGRect(x: cx - 2, y: cy + r * 1.25, width: 4, height: 4)
            context.fill(Path(ellipseIn: knotRect), with: .color(balloon.balloonColor.color))
        }
    }

    /// Draws the arrow in its current state: stationary at the bow, angled while aiming,
    /// or in flight across the canvas.
    private func drawArrow(context: inout GraphicsContext, size: CGSize) {
        let baseX = viewModel.arrow.baseX * size.width
        let baseY = viewModel.bowY * size.height
        let arrowLength = viewModel.arrow.length * size.height

        switch viewModel.arrow.state {
        case .idle:
            drawArrowShape(
                context: &context,
                from: CGPoint(x: baseX, y: baseY),
                to: CGPoint(x: baseX, y: baseY - arrowLength),
                size: size
            )

        case .aiming(let angle):
            let tipX = baseX + sin(angle) * arrowLength
            let tipY = baseY - cos(angle) * arrowLength
            drawArrowShape(
                context: &context,
                from: CGPoint(x: baseX, y: baseY),
                to: CGPoint(x: tipX, y: tipY),
                size: size
            )

        case .flying(let x, let y, let angle):
            let px = x * size.width
            let py = y * size.height
            let tailX = px - sin(angle) * arrowLength
            let tailY = py + cos(angle) * arrowLength
            drawArrowShape(
                context: &context,
                from: CGPoint(x: tailX, y: tailY),
                to: CGPoint(x: px, y: py),
                size: size
            )
        }
    }

    /// Draws the arrow body consisting of a brown shaft, a gray arrowhead triangle,
    /// and red fletching lines at the tail.
    private func drawArrowShape(
        context: inout GraphicsContext,
        from tail: CGPoint,
        to tip: CGPoint,
        size: CGSize
    ) {
        // Shaft
        var shaft = Path()
        shaft.move(to: tail)
        shaft.addLine(to: tip)
        context.stroke(shaft, with: .color(.brown), lineWidth: 3)

        // Arrowhead
        let dx = tip.x - tail.x
        let dy = tip.y - tail.y
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0 else { return }

        let unitX = dx / length
        let unitY = dy / length
        let headLength: CGFloat = 12
        let headWidth: CGFloat = 6

        let left = CGPoint(
            x: tip.x - unitX * headLength + unitY * headWidth,
            y: tip.y - unitY * headLength - unitX * headWidth
        )
        let right = CGPoint(
            x: tip.x - unitX * headLength - unitY * headWidth,
            y: tip.y - unitY * headLength + unitX * headWidth
        )

        var head = Path()
        head.move(to: tip)
        head.addLine(to: left)
        head.addLine(to: right)
        head.closeSubpath()
        context.fill(head, with: .color(.gray))

        // Fletching (feathers at the tail)
        let fletchLength: CGFloat = 8
        let fletchWidth: CGFloat = 4
        let fletchLeft = CGPoint(
            x: tail.x + unitX * fletchLength + unitY * fletchWidth,
            y: tail.y + unitY * fletchLength - unitX * fletchWidth
        )
        let fletchRight = CGPoint(
            x: tail.x + unitX * fletchLength - unitY * fletchWidth,
            y: tail.y + unitY * fletchLength + unitX * fletchWidth
        )
        var fletch = Path()
        fletch.move(to: tail)
        fletch.addLine(to: fletchLeft)
        fletch.move(to: tail)
        fletch.addLine(to: fletchRight)
        context.stroke(fletch, with: .color(.red), lineWidth: 2)
    }

    /// Draws the bow at the bottom of the screen as a curved wooden limb with a taut bowstring.
    private func drawBow(context: inout GraphicsContext, size: CGSize) {
        let baseX = viewModel.arrow.baseX * size.width
        let baseY = viewModel.bowY * size.height
        let bowWidth: CGFloat = 30
        let bowHeight: CGFloat = 50

        // Left curve of the bow
        var bowPath = Path()
        bowPath.move(to: CGPoint(x: baseX, y: baseY + bowHeight / 2))
        bowPath.addQuadCurve(
            to: CGPoint(x: baseX, y: baseY - bowHeight / 2),
            control: CGPoint(x: baseX - bowWidth, y: baseY)
        )
        context.stroke(bowPath, with: .color(Color(red: 0.55, green: 0.27, blue: 0.07)), lineWidth: 4)

        // Bowstring
        var stringPath = Path()
        stringPath.move(to: CGPoint(x: baseX, y: baseY + bowHeight / 2))
        stringPath.addLine(to: CGPoint(x: baseX, y: baseY - bowHeight / 2))
        context.stroke(stringPath, with: .color(.white.opacity(0.6)), lineWidth: 1.5)
    }

    /// Draws a dashed aim-assist line from the bow in the current aim direction,
    /// visible only while the player is actively aiming.
    private func drawAimLine(context: inout GraphicsContext, size: CGSize) {
        guard case .aiming(let angle) = viewModel.arrow.state else { return }
        let baseX = viewModel.arrow.baseX * size.width
        let baseY = viewModel.bowY * size.height
        let lineLength = size.height * 0.5

        let endX = baseX + sin(angle) * lineLength
        let endY = baseY - cos(angle) * lineLength

        var path = Path()
        path.move(to: CGPoint(x: baseX, y: baseY))
        path.addLine(to: CGPoint(x: endX, y: endY))

        context.stroke(
            path,
            with: .color(.white.opacity(0.3)),
            style: StrokeStyle(lineWidth: 1, dash: [5, 5])
        )
    }

    /// Draws expanding, fading particle bursts at the locations where balloons were popped.
    /// Each burst consists of 8 particles radiating outward in a circle.
    private func drawPopEffects(context: inout GraphicsContext, size: CGSize, date: Date) {
        for effect in viewModel.popEffects {
            let progress = effect.progress(at: date)
            let cx = effect.x * size.width
            let cy = effect.y * size.height
            let opacity = 1.0 - progress
            let spread = progress * size.width * 0.08

            for i in 0..<8 {
                let angle = Double(i) * (.pi / 4)
                let px = cx + cos(angle) * spread
                let py = cy + sin(angle) * spread
                let particleSize = 6.0 * (1.0 - progress)
                let rect = CGRect(
                    x: px - particleSize / 2,
                    y: py - particleSize / 2,
                    width: particleSize,
                    height: particleSize
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(effect.color.opacity(opacity))
                )
            }
        }
    }
}
