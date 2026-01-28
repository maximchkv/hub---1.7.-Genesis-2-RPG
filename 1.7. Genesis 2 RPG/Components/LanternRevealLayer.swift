import SwiftUI

/// An interactive "lantern" reveal layer: inside a soft radial mask we show
/// ink-style art (tower + runes + dust) over the parchment background.
///
/// Designed to sit *between* `UIStyle.background()` and the main UI.
struct LanternRevealLayer: View {
    var lightPoint: CGPoint
    var radius: CGFloat
    var feather: CGFloat

    private let runeCount: Int = 26
    private let dustCount: Int = 44

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let safeSize = CGSize(width: max(1, size.width), height: max(1, size.height))
            let r = max(120, radius)
            let f = min(max(12, feather), r * 0.85)
            let unitCenter = UnitPoint(
                x: clamp01(lightPoint.x / safeSize.width),
                y: clamp01(lightPoint.y / safeSize.height)
            )
            let innerStop = clamp01((r - f) / r)

            ZStack {
                // Revealed ink layer — abstract runes + dust (без силуэта башни)
                ZStack {
                    runeField(in: safeSize)
                    LanternDust(count: dustCount)
                }
                .compositingGroup()
                .mask(
                    Rectangle()
                        .fill(
                            RadialGradient(
                                stops: [
                                    .init(color: .white.opacity(1.0), location: 0.0),
                                    .init(color: .white.opacity(1.0), location: innerStop),
                                    .init(color: .white.opacity(0.0), location: 1.0),
                                ],
                                center: unitCenter,
                                startRadius: 0,
                                endRadius: r
                            )
                        )
                )

                // Warm bloom (subtle, helps the effect "pop" without darkening UI)
                Circle()
                    .fill(Color(red: 0.95, green: 0.86, blue: 0.60).opacity(0.10))
                    .frame(width: r * 1.4, height: r * 1.4)
                    .position(lightPoint)
                    .blur(radius: 18)
                    .blendMode(.screen)
                    .allowsHitTesting(false)

                // Thin rim hinting at the lantern edge
                Circle()
                    .stroke(Color.black.opacity(0.10), lineWidth: 1)
                    .frame(width: r * 2.0, height: r * 2.0)
                    .position(lightPoint)
                    .blur(radius: 0.2)
                    .opacity(0.25)
                    .allowsHitTesting(false)
            }
            .frame(width: safeSize.width, height: safeSize.height)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Layers

    private func towerInkLayer(in size: CGSize) -> some View {
        // Deprecated: ранее использовал силуэт башни.
        // Оставлено как пустой слой на случай будущего переиспользования.
        Color.clear
            .frame(width: size.width, height: size.height)
    }

    private func runeField(in size: CGSize) -> some View {
        let glyphs: [String] = ["✶", "✦", "⟡", "✷", "✧", "✢"]

        return ZStack {
            ForEach(0..<runeCount, id: \.self) { i in
                let x = hash01(Double(i) * 17.13) * size.width
                let y = hash01(Double(i) * 91.71) * size.height
                let g = glyphs[Int(hash01(Double(i) * 7.7) * Double(glyphs.count)) % glyphs.count]
                let s = 12 + hash01(Double(i) * 41.9) * 14

                Text(g)
                    .font(.system(size: s, weight: .semibold, design: .serif))
                    .foregroundStyle(UIStyle.Colors.inkPrimary.opacity(0.22))
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                    .rotationEffect(.degrees(hash01(Double(i) * 33.3) * 360))
                    .position(x: x, y: y)
            }

            // A faint ink ring pattern for extra texture
            RoundedRectangle(cornerRadius: 48)
                .stroke(UIStyle.Colors.inkPrimary.opacity(0.08), lineWidth: 1)
                .frame(width: size.width * 0.78, height: size.height * 0.55)
                .rotationEffect(.degrees(-6))
                .offset(y: -size.height * 0.06)
        }
        .blendMode(.multiply)
        .opacity(0.95)
    }

    // MARK: - Helpers

    private func clamp01(_ v: CGFloat) -> CGFloat {
        min(1, max(0, v))
    }

    private func hash01(_ x: Double) -> Double {
        // Deterministic "random" 0...1 from a number.
        let s = sin(x) * 43758.5453123
        return s - floor(s)
    }
}

/// Cheap drifting "dust" particles for the lantern reveal.
private struct LanternDust: View {
    let count: Int

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { ctx in
            Canvas { context, size in
                let t = ctx.date.timeIntervalSinceReferenceDate
                let w = max(1, size.width)
                let h = max(1, size.height)

                for i in 0..<count {
                    let seed = Double(i) * 31.73
                    let baseX = fract(sin(seed * 2.11) * 10000.0) * w
                    let baseY = fract(sin(seed * 5.17) * 10000.0) * h
                    let speed = 10.0 + fract(sin(seed * 9.31) * 10000.0) * 26.0

                    let driftX = sin(t * 0.45 + seed) * 10.0
                    let y = (baseY - t * speed).truncatingRemainder(dividingBy: h)
                    let py = (y < 0) ? (y + h) : y

                    let r = 0.8 + fract(sin(seed * 12.91) * 10000.0) * 1.8
                    let alpha = 0.06 + fract(sin(seed * 3.77) * 10000.0) * 0.10

                    let rect = CGRect(
                        x: baseX + driftX - r,
                        y: py - r,
                        width: r * 2,
                        height: r * 2
                    )

                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(UIStyle.Colors.inkPrimary.opacity(alpha))
                    )
                }
            }
        }
        .blendMode(.multiply)
        .opacity(0.9)
    }

    private func fract(_ v: Double) -> Double {
        v - floor(v)
    }
}

