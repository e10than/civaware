//
//  ConfettiView.swift
//  CongressionalAppChallenge
//

import SwiftUI

/// A one-shot burst of confetti. Skipped when Reduce Motion is on.
struct ConfettiView: View {
    private struct Piece {
        let x: Double, speed: Double, size: Double, sway: Double, freq: Double
        let spin: Double, delay: Double, color: Color
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var pieces: [Piece] = {
        let colors: [Color] = [Theme.gold, Theme.blue, Theme.red, Theme.green, Theme.purple, Theme.orange]
        return (0..<80).map { _ in
            Piece(x: .random(in: 0...1), speed: .random(in: 220...420), size: .random(in: 7...13),
                  sway: .random(in: 10...40), freq: .random(in: 2...5), spin: .random(in: -6...6),
                  delay: .random(in: 0...0.6), color: colors.randomElement()!)
        }
    }()

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSince(start)
                    for p in pieces {
                        let tt = t - p.delay
                        guard tt > 0, tt < 3.4 else { continue }
                        let x = p.x * size.width + sin(tt * p.freq) * p.sway
                        let y = -20 + tt * p.speed
                        var c = context
                        c.opacity = tt > 2.6 ? max(0, 1 - (tt - 2.6) / 0.8) : 1
                        c.translateBy(x: x, y: y)
                        c.rotate(by: .radians(tt * p.spin))
                        c.fill(Path(roundedRect: CGRect(x: -p.size / 2, y: -p.size / 3, width: p.size, height: p.size * 0.66), cornerRadius: 2),
                               with: .color(p.color))
                    }
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
            .accessibilityHidden(true)
        }
    }
}
