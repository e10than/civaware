//
//  LessonView.swift
//  CongressionalAppChallenge
//
//  A lesson is a short run of cards, then a quiz with instant feedback,
//  then a celebration screen that shows sources and a real-world action.
//

import SwiftUI

struct LessonView: View {
    @Environment(ProgressStore.self) private var progress
    @Environment(\.dismiss) private var dismiss
    let lesson: Lesson
    let unit: Unit

    private enum Phase { case cards, quiz, result }
    @State private var phase = Phase.cards
    @State private var cardIndex = 0
    @State private var questionIndex = 0
    @State private var picked: Int?
    @State private var correct = 0
    @State private var startXP = 0

    private var color: Color { Theme.unitColor(unit.color) }

    var body: some View {
        VStack(spacing: 0) {
            if phase != .result { topBar }
            Group {
                switch phase {
                case .cards: cardStage
                case .quiz: quizStage
                case .result: resultStage
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
        }
        .background(Theme.background)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { startXP = progress.xp }
    }

    private var overallProgress: Double {
        let total = Double(lesson.cards.count + lesson.quiz.count)
        switch phase {
        case .cards: return Double(cardIndex) / total
        case .quiz: return Double(lesson.cards.count + questionIndex + (picked != nil ? 1 : 0)) / total
        case .result: return 1
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.title3.weight(.heavy)).foregroundStyle(.secondary)
            }
            .accessibilityLabel("Close lesson")
            ChunkyProgressBar(value: overallProgress, color: color)
        }
        .padding(.horizontal).padding(.top, 10).padding(.bottom, 4)
    }

    // MARK: Cards

    private var cardStage: some View {
        let card = lesson.cards[cardIndex]
        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    IconBadge(systemName: unit.icon, color: color, size: 64)
                    Text(card.heading).font(.system(size: 30, weight: .black, design: .rounded))
                    Text(card.body).font(.title3.weight(.medium)).lineSpacing(5)
                }
                .padding(.horizontal, 24).padding(.top, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .id(cardIndex)
            }
            Button(cardIndex == lesson.cards.count - 1 ? "Start quiz" : "Continue") {
                Feedback.play(.whoosh, haptic: .light)
                withAnimation(.snappy) {
                    if cardIndex == lesson.cards.count - 1 { phase = .quiz } else { cardIndex += 1 }
                }
            }
            .buttonStyle(PrimaryButtonStyle(color: color))
            .padding()
        }
    }

    // MARK: Quiz

    private var quizStage: some View {
        let q = lesson.quiz[questionIndex]
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("QUESTION \(questionIndex + 1) OF \(lesson.quiz.count)")
                    .font(.caption.weight(.heavy)).foregroundStyle(.secondary)
                Text(q.prompt).font(.system(size: 26, weight: .heavy, design: .rounded)).padding(.bottom, 6)
                ForEach(q.choices.indices, id: \.self) { i in
                    choiceButton(q, i)
                }
            }
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 24)
            .id(questionIndex)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let picked { feedbackPanel(q, picked) }
        }
    }

    private func choiceButton(_ q: Question, _ i: Int) -> some View {
        let revealed = picked != nil
        let isAnswer = i == q.answer
        let isPicked = picked == i
        let tint: Color? = revealed ? (isAnswer ? Theme.green : (isPicked ? Theme.red : nil)) : nil
        return Button {
            guard picked == nil else { return }
            withAnimation(.snappy) { picked = i }
            if i == q.answer {
                correct += 1
                Feedback.play(.correct, haptic: .success)
            } else {
                Feedback.play(.wrong, haptic: .error)
            }
        } label: {
            HStack(spacing: 12) {
                Text(["A", "B", "C", "D"][min(i, 3)])
                    .font(.subheadline.weight(.heavy))
                    .frame(width: 30, height: 30)
                    .background(Circle().strokeBorder(tint ?? Theme.border, lineWidth: 2))
                Text(q.choices[i]).font(.body.weight(.semibold)).multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if revealed && isAnswer { Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.green) }
                else if revealed && isPicked { Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.red) }
            }
            .foregroundStyle(.primary)
        }
        .buttonStyle(ChoiceStyle(tint: tint))
        .disabled(revealed)
        .opacity(revealed && !isAnswer && !isPicked ? 0.55 : 1)
    }

    private func feedbackPanel(_ q: Question, _ picked: Int) -> some View {
        let right = picked == q.answer
        let tint = right ? Theme.green : Theme.red
        return VStack(alignment: .leading, spacing: 10) {
            Label(right ? "Correct!" : "Not quite", systemImage: right ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title3.weight(.heavy)).foregroundStyle(tint)
            Text(q.explanation).font(.subheadline.weight(.medium))
            Button(questionIndex == lesson.quiz.count - 1 ? "Finish" : "Continue") { advanceQuiz() }
                .buttonStyle(PrimaryButtonStyle(color: tint))
        }
        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                .fill(Theme.surface)
                .overlay(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24).fill(tint.opacity(0.14)))
                .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
        }
        .transition(.move(edge: .bottom))
        .accessibilityElement(children: .contain)
    }

    private func advanceQuiz() {
        Feedback.play(.whoosh)
        withAnimation(.snappy) {
            picked = nil
            if questionIndex == lesson.quiz.count - 1 {
                progress.completeLesson(lesson, correct: correct)
                phase = .result
                Feedback.play(.complete, haptic: .success)
            } else {
                questionIndex += 1
            }
        }
    }

    // MARK: Result

    private var resultStage: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 10) {
                        Image(systemName: correct == lesson.quiz.count ? "trophy.fill" : "checkmark.seal.fill")
                            .font(.system(size: 72)).foregroundStyle(Theme.gold)
                            .symbolEffect(.bounce, value: phase == .result)
                        Text(correct == lesson.quiz.count ? "Perfect!" : "Lesson complete!")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                        Text("\(correct) of \(lesson.quiz.count) correct").font(.headline).foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    HStack(spacing: 12) {
                        resultStat("bolt.fill", "+\(max(0, progress.xp - startXP)) XP", Theme.gold)
                        resultStat("flame.fill", "\(progress.streak) day streak", Theme.orange)
                    }

                    if let action = lesson.action {
                        Card(tint: Theme.green) {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Put it into practice", systemImage: "megaphone.fill").font(.headline.weight(.heavy))
                                Text(action.title).font(.subheadline.weight(.bold))
                                Text(action.detail).font(.subheadline)
                                Text("Find this on the Act tab.").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }

                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Sources", systemImage: "link").font(.headline.weight(.heavy))
                            ForEach(lesson.sources, id: \.url) { source in
                                if let url = URL(string: source.url) {
                                    Link(source.title, destination: url).font(.subheadline.weight(.semibold))
                                }
                            }
                        }
                    }

                    Button("Done") { dismiss() }.buttonStyle(PrimaryButtonStyle(color: color))
                }
                .padding()
            }
            ConfettiView()
        }
    }

    private func resultStat(_ icon: String, _ text: String, _ color: Color) -> some View {
        Card(tint: color) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Text(text).font(.subheadline.weight(.heavy))
            }
            .frame(maxWidth: .infinity)
        }
    }
}
