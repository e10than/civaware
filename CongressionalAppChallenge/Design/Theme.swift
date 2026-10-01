//
//  Theme.swift
//  CongressionalAppChallenge
//
//  CivAware's look: deep navy, capitol gold and cardinal red on warm cream
//  (or midnight in dark mode). Chunky, tactile controls in the spirit of
//  the best learning apps, but with a civic identity of its own.
//

import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255,
                  blue: Double(hex & 255) / 255)
    }

    /// A color that switches with light/dark mode.
    static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light)) })
    }

    /// The darker shade used for the "3D" bottom edge of chunky controls.
    var edge: Color { mix(with: .black, by: 0.28) }
}

enum Theme {
    static let background = Color.adaptive(0xF7F2E8, 0x0E1528)
    static let surface = Color.adaptive(0xFFFFFF, 0x19233F)
    static let border = Color.adaptive(0xE4DCC8, 0x2A3960)

    static let navy = Color(hex: 0x14213D)
    static let blue = Color.adaptive(0x2F5BEA, 0x5B84FF)
    static let gold = Color(hex: 0xF5B301)
    static let green = Color.adaptive(0x2FB56B, 0x3DCB7B)
    static let red = Color.adaptive(0xE5484D, 0xF2676B)
    static let purple = Color.adaptive(0x7C4DFF, 0x9C7BFF)
    static let orange = Color(hex: 0xFF8A1F)

    static let accent = blue

    static func unitColor(_ name: String) -> Color {
        switch name {
        case "blue": return blue
        case "purple": return purple
        case "green": return green
        case "orange": return orange
        case "red": return red
        case "teal": return Color.adaptive(0x0E9AA7, 0x2CC4D1)
        case "pink": return Color.adaptive(0xE0468C, 0xF06AA6)
        default: return blue
        }
    }
}

// MARK: - Card

struct Card<Content: View>: View {
    var tint: Color? = nil
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    shape.fill(tint?.opacity(0.35) ?? Theme.border).offset(y: 3)
                    shape.fill(Theme.surface)
                    if let tint { shape.fill(tint.opacity(0.13)) }
                    shape.strokeBorder(tint?.opacity(0.55) ?? Theme.border, lineWidth: 2)
                }
            }
            .padding(.bottom, 3)
    }
}

// MARK: - Buttons

/// Big, tactile button with a pressed-down 3D edge. Plays a soft tap.
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Theme.blue
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        let pressed = configuration.isPressed
        configuration.label
            .font(.headline.weight(.heavy))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(shape.fill(color))
            .background(shape.fill(color.edge).offset(y: pressed ? 0 : 4))
            .offset(y: pressed ? 4 : 0)
            .padding(.bottom, 4)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(.easeOut(duration: 0.08), value: pressed)
            .onChange(of: pressed) { _, isPressed in if isPressed { Feedback.play(.tap) } }
    }
}

/// A tappable option row (quiz answers, simulator choices).
struct ChoiceStyle: ButtonStyle {
    var tint: Color? = nil

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        let pressed = configuration.isPressed
        configuration.label
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    shape.fill(tint?.opacity(0.4) ?? Theme.border).offset(y: pressed ? 0 : 3)
                    shape.fill(Theme.surface)
                    if let tint { shape.fill(tint.opacity(0.14)) }
                    shape.strokeBorder(tint ?? Theme.border, lineWidth: 2)
                }
            }
            .offset(y: pressed ? 3 : 0)
            .padding(.bottom, 3)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

// MARK: - Progress bar

struct ChunkyProgressBar: View {
    var value: Double
    var color: Color = Theme.green
    var height: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.border)
                Capsule().fill(color)
                    .frame(width: max(height, geo.size.width * CGFloat(min(max(value, 0), 1))))
                    .overlay(alignment: .top) {
                        Capsule().fill(.white.opacity(0.3)).frame(height: height * 0.28).padding(.horizontal, height * 0.4).padding(.top, height * 0.2)
                    }
                    .opacity(value > 0 ? 1 : 0)
            }
        }
        .frame(height: height)
        .animation(.spring(duration: 0.4), value: value)
        .accessibilityElement()
        .accessibilityValue("\(Int(value * 100)) percent")
    }
}

// MARK: - Icon badge

struct IconBadge: View {
    let systemName: String
    var color: Color = Theme.blue
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.45, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(color))
            .background(Circle().fill(color.edge).offset(y: 3))
            .padding(.bottom, 3)
            .accessibilityHidden(true)
    }
}
