//
//  SimulateView.swift
//  CongressionalAppChallenge
//

import SwiftUI

struct SimulateView: View {
    @Environment(ProgressStore.self) private var progress

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Learn by doing. Make the calls real lawmakers and city leaders have to make. There's no perfect answer.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    link(SpotTheSpinView(), "Spot the Spin", "Sort trustworthy news from opinion and misinformation. Learn the tells that fact-checkers look for.", "eye.fill", Theme.orange, done: progress.didSimulation("spin"))
                    link(BuildABillView(), "Build a Bill", "Take your own idea from introduction to the President's desk. Most bills never make it. Will yours?", "scroll.fill", Theme.purple, done: progress.didSimulation("bill"))
                    link(CityBudgetView(), "Balance the City Budget", "You have $10 million and five priorities. Every choice helps someone and costs someone else.", "building.2.fill", Theme.green, done: progress.didSimulation("budget"))
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Simulate")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func link<D: View>(_ dest: D, _ title: String, _ blurb: String, _ icon: String, _ color: Color, done: Bool) -> some View {
        NavigationLink { dest } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    IconBadge(systemName: icon, color: color, size: 52)
                    Spacer()
                    if done { Label("PLAYED", systemImage: "checkmark.circle.fill").font(.caption.weight(.heavy)).foregroundStyle(color) }
                }
                Text(title).font(.title2.weight(.black)).foregroundStyle(.primary)
                Text(blurb).font(.subheadline.weight(.medium)).foregroundStyle(.secondary).multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(ChoiceStyle(tint: color))
        .simultaneousGesture(TapGesture().onEnded { Feedback.play(.pop, haptic: .light) })
    }
}
