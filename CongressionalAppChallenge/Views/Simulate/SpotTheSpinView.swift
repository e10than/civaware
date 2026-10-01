//
//  SpotTheSpinView.swift
//  CongressionalAppChallenge
//
//  Media-literacy game: classify made-up posts as trustworthy news,
//  opinion, or "needs checking", then learn the tells. Every example is
//  fictional, and nothing here touches real people or real politics.
//

import SwiftUI

private enum PostKind: String, CaseIterable {
    case trustworthy = "Trustworthy news"
    case opinion = "Opinion"
    case check = "Needs checking"

    var icon: String {
        switch self {
        case .trustworthy: return "checkmark.seal.fill"
        case .opinion: return "text.bubble.fill"
        case .check: return "magnifyingglass"
        }
    }
    var color: Color {
        switch self {
        case .trustworthy: return Theme.green
        case .opinion: return Theme.blue
        case .check: return Theme.orange
        }
    }
}

private struct Post {
    let source: String
    let headline: String
    let detail: String
    let kind: PostKind
    let why: String
}

struct SpotTheSpinView: View {
    @Environment(ProgressStore.self) private var progress

    private static let posts: [Post] = [
        Post(source: "viral-news-now.example · no author · no date",
             headline: "SHOCKING!!! City hall doesn't want you to see this ONE weird trick",
             detail: "Click to find out what THEY are hiding. Share before it's deleted!",
             kind: .check,
             why: "All caps, big emotion, no evidence, no author, and pressure to share fast. These are classic red flags."),
        Post(source: "Riverbend Gazette · by Dana Ortiz · Oct 3",
             headline: "City council votes 5–2 to extend library hours on weekends",
             detail: "Two council members who voted no said the cost was too high. The meeting minutes are linked at the bottom of the article.",
             kind: .trustworthy,
             why: "A named reporter, a date, both sides quoted, and a link to the primary source (the meeting minutes)."),
        Post(source: "Screenshot shared by @realtruth4587 · posted 2:04 a.m.",
             headline: "BREAKING: All schools closing forever tomorrow!! SHARE NOW",
             detail: "No link, no source, just an image of text.",
             kind: .check,
             why: "An anonymous account, no link, urgent language, and an extreme claim. Check the school district's official site before sharing."),
        Post(source: "Riverbend Gazette · Opinion · by Sam Lee, student columnist",
             headline: "Why our town needs a skate park",
             detail: "\"Every teen deserves a safe place to skate. Here's what I think the council should do...\"",
             kind: .opinion,
             why: "It's labeled Opinion and argues for a position. It can be well argued, but it isn't a neutral report of events."),
        Post(source: "Teen Poll Daily · study",
             headline: "STUDY PROVES 100% of teens would vote if it were on their phones",
             detail: "Based on a survey of 12 students in one classroom.",
             kind: .check,
             why: "Tiny sample, an absolute claim (100%), and a big conclusion. Ask how many people were surveyed and how they were chosen."),
        Post(source: "County Elections Office (official site) · updated Oct 1",
             headline: "Voter registration deadline is October 12. Find your polling place.",
             detail: "Includes phone number, address, and links to state election rules.",
             kind: .trustworthy,
             why: "An official government source, recently updated, with contact details. For deadlines, always confirm on your official state or county site.")
    ]

    @State private var index = 0
    @State private var picked: PostKind?
    @State private var score = 0
    @State private var finished = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if finished { summary } else { round }
            }
            .padding()
        }
        .background(Theme.background)
        .overlay { if finished && score >= 5 { ConfettiView() } }
        .navigationTitle("Spot the Spin")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var round: some View {
        let post = Self.posts[index]
        return VStack(alignment: .leading, spacing: 14) {
            Text("POST \(index + 1) OF \(Self.posts.count) · ALL EXAMPLES ARE FICTIONAL")
                .font(.caption.weight(.heavy)).foregroundStyle(.secondary)
            Card {
                VStack(alignment: .leading, spacing: 8) {
                    Text(post.source).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Text(post.headline).font(.title3.weight(.heavy))
                    Text(post.detail).font(.subheadline)
                }
            }
            Text("How would you treat this?").font(.headline.weight(.heavy))
            ForEach(PostKind.allCases, id: \.self) { kind in
                choice(kind, post)
            }
            if let picked {
                let right = picked == post.kind
                Card(tint: right ? Theme.green : Theme.red) {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(right ? "Nice catch!" : "It's actually: \(post.kind.rawValue)",
                              systemImage: right ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.headline.weight(.heavy)).foregroundStyle(right ? Theme.green : Theme.red)
                        Text(post.why).font(.subheadline)
                    }
                }
                Button(index == Self.posts.count - 1 ? "See results" : "Next post") { next() }
                    .buttonStyle(PrimaryButtonStyle(color: Theme.orange))
            }
        }
    }

    private func choice(_ kind: PostKind, _ post: Post) -> some View {
        let revealed = picked != nil
        let tint: Color? = revealed ? (kind == post.kind ? Theme.green : (kind == picked ? Theme.red : nil)) : nil
        return Button {
            guard picked == nil else { return }
            withAnimation(.snappy) { picked = kind }
            if kind == post.kind {
                score += 1
                Feedback.play(.correct, haptic: .success)
            } else {
                Feedback.play(.wrong, haptic: .error)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: kind.icon).frame(width: 28).foregroundStyle(kind.color)
                Text(kind.rawValue)
            }
            .font(.body.weight(.bold)).foregroundStyle(.primary)
        }
        .buttonStyle(ChoiceStyle(tint: tint))
        .disabled(revealed)
        .opacity(revealed && tint == nil ? 0.55 : 1)
    }

    private func next() {
        Feedback.play(.whoosh)
        withAnimation(.snappy) {
            picked = nil
            if index == Self.posts.count - 1 {
                finished = true
                progress.completeSimulation("spin")
                Feedback.play(.complete, haptic: .success)
            } else {
                index += 1
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "eye.fill").font(.system(size: 56)).foregroundStyle(Theme.orange)
            Text("You spotted \(score) of \(Self.posts.count)").font(.largeTitle.weight(.black))
            Card(tint: Theme.orange) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your 5-second check").font(.headline.weight(.heavy))
                    Text("1. Who made this, and can I find them?\n2. What's the evidence, and can I see the original?\n3. Do other reliable sources say the same?\n4. Is it trying to make me angry or rush me?")
                        .font(.subheadline)
                }
            }
            Button("Play again") {
                withAnimation { index = 0; picked = nil; score = 0; finished = false }
            }
            .buttonStyle(PrimaryButtonStyle(color: Theme.orange))
        }
    }
}
