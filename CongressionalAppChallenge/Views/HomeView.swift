//
//  HomeView.swift
//  CongressionalAppChallenge
//

import SwiftUI

struct HomeView: View {
    @Environment(ProgressStore.self) private var progress
    var goTo: (Int) -> Void
    private let library = ContentLibrary.shared

    private var wordOfTheDay: Word? {
        guard !library.words.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return library.words[day % library.words.count]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    continueCard
                    DailyQuestionCard()
                    if let word = wordOfTheDay { wordCard(word) }
                    Text("Jump in").font(.title3.weight(.heavy)).padding(.top, 4)
                    HStack(spacing: 12) {
                        shortcut("Build a Bill", "scroll.fill", Theme.purple) { goTo(2) }
                        shortcut("Find My Reps", "person.3.fill", Theme.green) { goTo(3) }
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: Hero

    private var hero: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CivAware").font(.system(size: 38, weight: .black, design: .rounded))
                    Text("Stay aware.\nStay involved.").font(.subheadline.weight(.semibold)).opacity(0.85)
                }
                Spacer()
                Image(systemName: "star.circle.fill").font(.system(size: 44)).foregroundStyle(Theme.gold)
            }
            HStack(spacing: 10) {
                pill("flame.fill", "\(progress.streak)", "streak", Theme.orange)
                pill("bolt.fill", "\(progress.xp)", "XP", Theme.gold)
                pill("megaphone.fill", "\(progress.completedActionCount)", "actions", Theme.green)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Level \(progress.xp / 100 + 1)").font(.caption.weight(.heavy))
                    Spacer()
                    Text("\(progress.xp % 100)/100 XP").font(.caption.weight(.semibold)).opacity(0.8)
                }
                ChunkyProgressBar(value: Double(progress.xp % 100) / 100, color: Theme.gold, height: 12)
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background {
            ZStack {
                shape.fill(LinearGradient(colors: [Color(hex: 0x1B2E63), Color(hex: 0x2F5BEA)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "star.fill").font(.system(size: 160)).foregroundStyle(.white.opacity(0.06))
                    .offset(x: 110, y: -30).rotationEffect(.degrees(15))
            }
            .clipShape(shape)
        }
        .background(shape.fill(Color(hex: 0x0F1D45)).offset(y: 5))
        .padding(.bottom, 5)
    }

    private func pill(_ icon: String, _ value: String, _ label: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.headline.weight(.heavy)).contentTransition(.numericText())
                Text(label).font(.caption2.weight(.semibold)).opacity(0.75)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white.opacity(0.14)))
        .accessibilityElement(children: .combine)
    }

    // MARK: Continue

    @ViewBuilder private var continueCard: some View {
        if let lesson = progress.nextLesson(in: library), let unit = library.unit(for: lesson) {
            let color = Theme.unitColor(unit.color)
            NavigationLink {
                LessonView(lesson: lesson, unit: unit)
            } label: {
                HStack(spacing: 14) {
                    IconBadge(systemName: unit.icon, color: color, size: 54)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(progress.completedLessonCount == 0 ? "START HERE" : "UP NEXT")
                            .font(.caption.weight(.heavy)).foregroundStyle(color)
                        Text(lesson.title).font(.title3.weight(.heavy)).foregroundStyle(.primary)
                        Text("\(unit.title) · \(lesson.minutes) min").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right.circle.fill").font(.title).foregroundStyle(color)
                }
            }
            .buttonStyle(ChoiceStyle(tint: color))
        } else {
            Card(tint: Theme.green) {
                Label("You've finished every lesson! Try a simulation or take civic action.", systemImage: "checkmark.seal.fill")
                    .font(.headline)
            }
        }
    }

    private func wordCard(_ word: Word) -> some View {
        Card(tint: Theme.gold) {
            VStack(alignment: .leading, spacing: 6) {
                Label("WORD OF THE DAY", systemImage: "character.book.closed.fill")
                    .font(.caption.weight(.heavy)).foregroundStyle(Theme.gold.edge)
                Text(word.term).font(.title.weight(.black))
                Text(word.definition).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func shortcut(_ title: String, _ icon: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: { Feedback.play(.pop, haptic: .light); action() }) {
            VStack(alignment: .leading, spacing: 10) {
                IconBadge(systemName: icon, color: color, size: 44)
                Text(title).font(.headline.weight(.heavy)).foregroundStyle(.primary)
            }
        }
        .buttonStyle(ChoiceStyle(tint: color))
    }
}


// MARK: - Daily awareness question

private struct DailyQuestionCard: View {
    @Environment(ProgressStore.self) private var progress
    @State private var picked: Int?

    private var question: Question? {
        let all = ContentLibrary.shared.allLessons.flatMap(\.quiz)
        guard !all.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return all[day % all.count]
    }

    var body: some View {
        if let q = question {
            Card(tint: Theme.blue) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("TODAY'S AWARENESS QUESTION", systemImage: "brain.head.profile")
                        .font(.caption.weight(.heavy)).foregroundStyle(Theme.blue)
                    if progress.answeredDailyToday && picked == nil {
                        Label("Done for today. Come back tomorrow to keep your streak!", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.green)
                    } else {
                        Text(q.prompt).font(.headline.weight(.heavy))
                        ForEach(q.choices.indices, id: \.self) { i in
                            Button {
                                guard picked == nil else { return }
                                withAnimation(.snappy) { picked = i }
                                let right = i == q.answer
                                Feedback.play(right ? .correct : .wrong, haptic: right ? .success : .error)
                                progress.answerDaily(correct: right)
                            } label: {
                                HStack {
                                    Text(q.choices[i]).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                                    Spacer()
                                    if let picked {
                                        if i == q.answer { Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.green) }
                                        else if i == picked { Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.red) }
                                    }
                                }
                            }
                            .buttonStyle(ChoiceStyle(tint: picked == nil ? nil : (i == q.answer ? Theme.green : (i == picked ? Theme.red : nil))))
                            .disabled(picked != nil)
                        }
                        if picked != nil {
                            Text(q.explanation).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
