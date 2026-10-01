//
//  LearnView.swift
//  CongressionalAppChallenge
//
//  A winding path of lessons for each unit, so progress feels like a
//  journey rather than a list.
//

import SwiftUI

struct LearnView: View {
    @Environment(ProgressStore.self) private var progress
    private let library = ContentLibrary.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(library.units) { unit in
                        UnitSection(unit: unit)
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct UnitSection: View {
    @Environment(ProgressStore.self) private var progress
    let unit: Unit
    private let offsets: [CGFloat] = [0, 52, 0, -52]

    private var color: Color { Theme.unitColor(unit.color) }
    private var nextID: String? { ContentLibrary.shared.allLessons.first { !progress.isCompleted($0) }?.id }

    var body: some View {
        VStack(spacing: 18) {
            banner
            ForEach(Array(unit.lessons.enumerated()), id: \.element.id) { index, lesson in
                LessonNode(lesson: lesson, unit: unit, isNext: lesson.id == nextID)
                    .offset(x: offsets[index % offsets.count])
            }
        }
        .padding(.bottom, 28)
    }

    private var banner: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        let done = unit.lessons.filter(progress.isCompleted).count
        return HStack(spacing: 14) {
            Image(systemName: unit.icon).font(.system(size: 30, weight: .bold))
            VStack(alignment: .leading, spacing: 3) {
                Text(unit.title).font(.title3.weight(.heavy))
                Text(unit.blurb).font(.caption.weight(.medium)).opacity(0.9)
                Text("\(done) of \(unit.lessons.count) lessons").font(.caption2.weight(.heavy)).opacity(0.85).padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(color))
        .background(shape.fill(color.edge).offset(y: 4))
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct LessonNode: View {
    @Environment(ProgressStore.self) private var progress
    let lesson: Lesson
    let unit: Unit
    let isNext: Bool
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var color: Color { Theme.unitColor(unit.color) }
    private var done: Bool { progress.isCompleted(lesson) }

    var body: some View {
        NavigationLink {
            LessonView(lesson: lesson, unit: unit)
        } label: {
            VStack(spacing: 8) {
                if isNext {
                    Text("START")
                        .font(.caption.weight(.heavy)).foregroundStyle(color)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(Capsule().fill(Theme.surface))
                        .overlay(Capsule().strokeBorder(color, lineWidth: 2))
                }
                ZStack {
                    if isNext && !reduceMotion {
                        Circle().stroke(color.opacity(0.35), lineWidth: 6)
                            .frame(width: 96, height: 96).scaleEffect(pulse ? 1.12 : 0.95).opacity(pulse ? 0 : 1)
                    }
                    Circle().fill(done || isNext ? color.edge : Theme.border).frame(width: 78, height: 78).offset(y: 5)
                    Circle().fill(done || isNext ? color : Theme.surface).frame(width: 78, height: 78)
                    if !(done || isNext) { Circle().strokeBorder(Theme.border, lineWidth: 3).frame(width: 78, height: 78) }
                    Image(systemName: done ? "checkmark" : (isNext ? "star.fill" : "book.fill"))
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(done || isNext ? .white : color)
                }
                .frame(height: 90)
                Text(lesson.title).font(.subheadline.weight(.bold)).foregroundStyle(.primary)
                    .multilineTextAlignment(.center).frame(width: 140)
                if let best = progress.bestScore(lesson) {
                    Text("\(best)/\(lesson.quiz.count) correct").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded { Feedback.play(.pop, haptic: .light) })
        .onAppear {
            guard isNext else { return }
            withAnimation(.easeOut(duration: 1.3).repeatForever(autoreverses: false)) { pulse = true }
        }
    }
}
