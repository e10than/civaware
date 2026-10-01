//
//  BuildABillView.swift
//  CongressionalAppChallenge
//
//  Take a bill through the real steps. Support is a simplified stand-in
//  for how many members are on board; each stage has a "gate" the bill has
//  to clear or it dies there, which mirrors how most real bills end.
//

import SwiftUI

private struct BillTopic: Identifiable {
    let id: String
    let name: String
    let pitch: String
    let icon: String
}

private struct BillChoice {
    let text: String
    let delta: Int
    let result: String
}

private struct BillStage {
    let title: String
    let icon: String
    let lesson: String
    let prompt: String
    let choices: [BillChoice]
    let gate: Int
    let failure: String
}

struct BuildABillView: View {
    @Environment(ProgressStore.self) private var progress

    private static let topics = [
        BillTopic(id: "start", name: "Later School Start Times", pitch: "Require middle and high schools to start after 8:30 a.m.", icon: "alarm.fill"),
        BillTopic(id: "wifi", name: "Free Library Wi-Fi", pitch: "Fund free public Wi-Fi hotspots that students can borrow.", icon: "wifi"),
        BillTopic(id: "walk", name: "Safer School Crosswalks", pitch: "Fund flashing signals and crossing guards near schools.", icon: "figure.walk")
    ]

    private static let stages: [BillStage] = [
        BillStage(
            title: "Introduction", icon: "pencil.and.list.clipboard",
            lesson: "Only a Member of Congress can introduce a bill, so your idea needs a sponsor. Bills with sponsors from both parties usually have a better shot.",
            prompt: "You've convinced a Representative to sponsor your bill. How should they launch it?",
            choices: [
                BillChoice(text: "Find a co-sponsor from the other party", delta: 15, result: "Bipartisan co-sponsors signal broad appeal. It takes time, but it pays off."),
                BillChoice(text: "Gather a petition of local supporters first", delta: 10, result: "A visible wave of constituents shows Members that voters care."),
                BillChoice(text: "Introduce it immediately, alone", delta: 0, result: "Fast, but nobody else has a stake in it yet.")
            ],
            gate: 0, failure: ""),
        BillStage(
            title: "Committee", icon: "person.3.sequence.fill",
            lesson: "Committees hold hearings and 'mark up' bills. This is where most bills die: the majority never get a vote.",
            prompt: "The committee chair signals concerns about cost and scope.",
            choices: [
                BillChoice(text: "Hold a hearing with experts and students", delta: 12, result: "Testimony gives members facts and stories to point to."),
                BillChoice(text: "Accept an amendment that narrows the bill", delta: 15, result: "A smaller bill is easier to pass. You give up some ambition to keep it alive."),
                BillChoice(text: "Refuse changes and insist on the original text", delta: -10, result: "Standing firm feels good, but the chair now has fewer reasons to help you.")
            ],
            gate: 45,
            failure: "The committee never scheduled a vote and the bill 'died in committee', which is the most common fate for bills."),
        BillStage(
            title: "House Floor", icon: "building.columns",
            lesson: "The full House debates and votes. A simple majority (218 of 435 if everyone votes) passes it.",
            prompt: "Leaders count votes and find a group of undecided members.",
            choices: [
                BillChoice(text: "Add a pilot-program version to win them over", delta: 10, result: "Testing the idea in a few places first makes 'yes' an easier vote."),
                BillChoice(text: "Call undecided members and explain the bill", delta: 8, result: "Personal outreach works, and it takes effort."),
                BillChoice(text: "Rush to a vote before opposition organizes", delta: -8, result: "Speed can backfire when members feel they haven't had time to study the bill.")
            ],
            gate: 55,
            failure: "The bill fell short of a majority on the House floor."),
        BillStage(
            title: "Senate Floor", icon: "building.2.crop.circle",
            lesson: "The Senate must pass the same text. Ending debate on many bills takes 60 votes (cloture), so compromise matters.",
            prompt: "A senator threatens a filibuster to delay the bill.",
            choices: [
                BillChoice(text: "Negotiate changes to reach the 60 votes needed", delta: 12, result: "Compromise gets you past the filibuster threat."),
                BillChoice(text: "Rally public support so senators hear from voters", delta: 6, result: "Public pressure helps, but it may not be enough alone."),
                BillChoice(text: "Refuse to compromise", delta: -12, result: "Without 60 votes to end debate, the bill stalls.")
            ],
            gate: 60,
            failure: "The bill stalled in the Senate without enough votes to end debate."),
        BillStage(
            title: "The President", icon: "signature",
            lesson: "The President can sign or veto. Congress can override a veto only with a two-thirds vote of both chambers.",
            prompt: "The bill is on the President's desk. Your coalition makes one last push.",
            choices: [
                BillChoice(text: "Invite students and advocates to the signing conversation", delta: 8, result: "Public stories can make it harder to say no."),
                BillChoice(text: "Quietly wait for the decision", delta: 0, result: "Sometimes patience is the only move left.")
            ],
            gate: 65,
            failure: "The President vetoed the bill, and Congress didn't have the two-thirds votes to override.")
    ]

    @State private var topic: BillTopic?
    @State private var stageIndex = 0
    @State private var support = 40
    @State private var lastResult: String?
    @State private var lastDelta = 0
    @State private var failedAt: Int?
    @State private var won = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if topic == nil { topicPicker }
                else if won { endCard(success: true) }
                else if failedAt != nil { endCard(success: false) }
                else { stageView }
            }
            .padding()
        }
        .background(Theme.background)
        .overlay { if won { ConfettiView() } }
        .navigationTitle("Build a Bill")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Topic

    private var topicPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pick an idea").font(.title2.bold())
            Text("Each is a real kind of issue students care about. You'll try to turn it into a law.")
                .foregroundStyle(.secondary)
            ForEach(Self.topics) { t in
                Button { Feedback.play(.pop, haptic: .light); topic = t } label: {
                    HStack(spacing: 12) {
                        IconBadge(systemName: t.icon, color: Theme.purple, size: 48)
                        VStack(alignment: .leading) {
                            Text(t.name).font(.headline.weight(.heavy)).foregroundStyle(.primary)
                            Text(t.pitch).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                        }
                    }
                }
                .buttonStyle(ChoiceStyle(tint: Theme.purple))
            }
        }
    }

    // MARK: Stage

    private var stageView: some View {
        let stage = Self.stages[stageIndex]
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                ForEach(Self.stages.indices, id: \.self) { i in
                    Capsule().fill(i <= stageIndex ? Theme.purple : Theme.border).frame(height: 6)
                }
            }
            .accessibilityHidden(true)
            supportMeter(needed: stage.gate)
            Label(stage.title, systemImage: stage.icon).font(.title.bold())
            Card { Text(stage.lesson).font(.subheadline) }

            if let lastResult {
                Card(tint: lastDelta >= 0 ? Theme.green : Theme.orange) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lastDelta >= 0 ? "+\(lastDelta) support" : "\(lastDelta) support").font(.headline)
                        Text(lastResult)
                    }
                }
                Button(stageIndex == Self.stages.count - 1 ? "See the outcome" : "Continue") { advance() }
                    .buttonStyle(PrimaryButtonStyle(color: Theme.purple))
            } else {
                Text(stage.prompt).font(.title3.bold())
                ForEach(stage.choices.indices, id: \.self) { i in
                    Button { choose(stage.choices[i]) } label: {
                        Text(stage.choices[i].text)
                            .font(.body.weight(.semibold))
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(ChoiceStyle())
                }
            }
        }
    }

    private func supportMeter(needed: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Support for \"\(topic?.name ?? "")\"").font(.caption.bold())
                Spacer()
                Text("\(support)%").font(.caption.bold())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.border)
                    Capsule().fill(Theme.purple).frame(width: geo.size.width * CGFloat(min(max(support, 0), 100)) / 100)
                    if needed > 0 {
                        Rectangle().fill(Theme.gold).frame(width: 3)
                            .offset(x: geo.size.width * CGFloat(needed) / 100)
                    }
                }
            }
            .frame(height: 14)
            if needed > 0 {
                Text("Needed to pass this step: \(needed)%").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Support \(support) percent. \(needed > 0 ? "Needed to pass this step: \(needed) percent." : "")")
    }

    private func choose(_ choice: BillChoice) {
        if choice.delta > 0 { Feedback.play(.correct, haptic: .success) }
        else if choice.delta < 0 { Feedback.play(.wrong, haptic: .warning) }
        else { Feedback.play(.pop, haptic: .light) }
        withAnimation {
            support += choice.delta
            lastDelta = choice.delta
            lastResult = choice.result
        }
    }

    private func advance() {
        let stage = Self.stages[stageIndex]
        withAnimation {
            lastResult = nil
            if stage.gate > 0 && support < stage.gate {
                Feedback.play(.gavel, haptic: .error)
                failedAt = stageIndex
                progress.completeSimulation("bill")
                return
            }
            if stageIndex == Self.stages.count - 1 {
                Feedback.play(.complete, haptic: .success)
                won = true
                progress.completeSimulation("bill")
            } else {
                Feedback.play(.whoosh)
                stageIndex += 1
            }
        }
    }

    // MARK: End

    private func endCard(success: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: success ? "checkmark.seal.fill" : "xmark.octagon.fill")
                .font(.system(size: 56)).foregroundStyle(success ? Theme.green : Theme.orange)
            Text(success ? "It's a law!" : "Your bill didn't pass").font(.largeTitle.bold())
            if success {
                Text("\"\(topic?.name ?? "")\" survived every step with \(support)% support. Real bills take months or years, and most never get this far.")
            } else if let failedAt {
                Text(Self.stages[failedAt].failure)
                Card(tint: Theme.orange) {
                    Text("Real lawmakers face this too. Only a small share of introduced bills ever become law. Try again with a different approach.")
                }
            }
            Card {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Want to do this for real?").font(.headline)
                    Text("Head to the Act tab to find your actual representatives and tell them about an issue you care about.")
                        .font(.subheadline)
                }
            }
            Button("Play again") {
                withAnimation { topic = nil; stageIndex = 0; support = 40; failedAt = nil; won = false; lastResult = nil }
            }
            .buttonStyle(PrimaryButtonStyle(color: Theme.purple))
        }
    }
}
