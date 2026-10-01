//
//  CityBudgetView.swift
//  CongressionalAppChallenge
//
//  Allocate $10M in $1M blocks. Four residents each care most about two
//  areas. Nobody can be fully satisfied, and then a storm tests the reserve.
//

import SwiftUI

private struct Area: Identifiable {
    let id: String
    let name: String
    let icon: String
    let detail: String
}

private struct Resident: Identifiable {
    let id: String
    let name: String
    let role: String
    let quote: String
    let wants: [String: Int]   // areaID -> blocks that would fully satisfy them
}

struct CityBudgetView: View {
    @Environment(ProgressStore.self) private var progress

    private static let areas = [
        Area(id: "roads", name: "Roads & Transit", icon: "bus.fill", detail: "Potholes, buses, bike lanes"),
        Area(id: "parks", name: "Parks & Recreation", icon: "tree.fill", detail: "Parks, fields, pools"),
        Area(id: "safety", name: "Police, Fire & EMS", icon: "cross.case.fill", detail: "Emergency response"),
        Area(id: "library", name: "Libraries & Youth Programs", icon: "books.vertical.fill", detail: "Libraries, after-school"),
        Area(id: "reserve", name: "Rainy-Day Reserve", icon: "banknote.fill", detail: "Saved for emergencies")
    ]

    private static let residents = [
        Resident(id: "maya", name: "Maya", role: "High school student",
                 quote: "I need safe places to hang out and somewhere to study after school.",
                 wants: ["library": 3, "parks": 2]),
        Resident(id: "carlos", name: "Carlos", role: "Small-business owner",
                 quote: "My deliveries and my customers both depend on decent roads and buses.",
                 wants: ["roads": 4, "safety": 2]),
        Resident(id: "priya", name: "Priya", role: "Nurse and parent",
                 quote: "Fast ambulances matter to me, and so do parks for my kids.",
                 wants: ["safety": 3, "parks": 2]),
        Resident(id: "walt", name: "Walt", role: "Retired teacher",
                 quote: "I worry about surprises. Please don't spend every last dollar.",
                 wants: ["reserve": 2, "library": 2])
    ]

    private static let totalBlocks = 10
    @State private var blocks: [String: Int] = ["roads": 0, "parks": 0, "safety": 0, "library": 0, "reserve": 0]
    @State private var submitted = false
    @State private var stormRevealed = false

    private var used: Int { blocks.values.reduce(0, +) }
    private var remaining: Int { Self.totalBlocks - used }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if submitted { results } else { allocation }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("City Budget")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Allocation

    private var allocation: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("You're on the city council").font(.title2.bold())
            Text("Divide $10 million (10 blocks of $1M) among five areas. Then hear how residents react.")
                .foregroundStyle(.secondary)

            Card(tint: remaining == 0 ? Theme.green : Theme.blue) {
                HStack {
                    Text("Blocks left").font(.headline)
                    Spacer()
                    Text("\(remaining)").font(.title.bold()).contentTransition(.numericText())
                }
            }
            .accessibilityElement(children: .combine)

            ForEach(Self.areas) { area in
                Card {
                    HStack {
                        Image(systemName: area.icon).frame(width: 30).foregroundStyle(Theme.blue)
                        VStack(alignment: .leading) {
                            Text(area.name).font(.headline)
                            Text(area.detail).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Stepper("\(area.name)", value: binding(area.id), in: 0...(blocks[area.id]! + remaining))
                            .labelsHidden()
                            .onChange(of: blocks[area.id]) { _, _ in Feedback.play(.pop, haptic: .light) }
                        Text("$\(blocks[area.id]!)M").font(.headline).frame(minWidth: 44, alignment: .trailing)
                    }
                }
            }

            Button("Submit budget") { Feedback.play(.gavel, haptic: .success); withAnimation { submitted = true; progress.completeSimulation("budget") } }
                .buttonStyle(PrimaryButtonStyle(color: Theme.green))
                .disabled(remaining != 0)
                .opacity(remaining == 0 ? 1 : 0.5)
        }
    }

    private func binding(_ id: String) -> Binding<Int> {
        Binding(get: { blocks[id] ?? 0 }, set: { blocks[id] = $0 })
    }

    // MARK: Results

    private func satisfaction(_ r: Resident) -> Double {
        let scores = r.wants.map { area, target in min(1.0, Double(blocks[area] ?? 0) / Double(target)) }
        return scores.reduce(0, +) / Double(max(scores.count, 1))
    }

    private var results: some View {
        let average = Self.residents.map(satisfaction).reduce(0, +) / Double(Self.residents.count)
        return VStack(alignment: .leading, spacing: 14) {
            Text("Residents react").font(.title2.bold())
            ForEach(Self.residents) { r in
                let s = satisfaction(r)
                Card {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(r.name), \(r.role)").font(.headline)
                            Spacer()
                            Text("\(Int(s * 100))% happy").font(.subheadline.bold())
                                .foregroundStyle(s >= 0.75 ? Theme.green : (s >= 0.4 ? Theme.orange : Theme.red))
                        }
                        Text("\"\(r.quote)\"").font(.subheadline).italic().foregroundStyle(.secondary)
                        ChunkyProgressBar(value: s, color: s >= 0.75 ? Theme.green : (s >= 0.4 ? Theme.orange : Theme.red), height: 12)
                    }
                }
                .accessibilityElement(children: .combine)
            }

            Card(tint: Theme.blue) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Average approval: \(Int(average * 100))%").font(.headline)
                    Text("Even great budgets leave someone disappointed. That is what makes local government hard, and why people showing up to meetings matters.")
                        .font(.subheadline)
                }
            }

            if !stormRevealed {
                Button("A storm hits the city…") { Feedback.play(.whoosh, haptic: .warning); withAnimation { stormRevealed = true } }
                    .buttonStyle(PrimaryButtonStyle(color: Theme.orange))
            } else {
                stormCard
                Button("Try a new budget") {
                    withAnimation {
                        blocks = blocks.mapValues { _ in 0 }
                        submitted = false
                        stormRevealed = false
                    }
                }
                .buttonStyle(PrimaryButtonStyle(color: Theme.green))
            }
        }
    }

    private var stormCard: some View {
        let reserve = blocks["reserve"] ?? 0
        let text: String
        let color: Color
        switch reserve {
        case 0:
            text = "A storm causes $2 million in damage and you have no reserve. The council must cut programs mid-year or borrow money. Reserves feel like wasted money until you need them."
            color = Theme.red
        case 1:
            text = "A storm causes $2 million in damage. Your $1M reserve covers half, and the council has to find the rest by trimming other spending."
            color = Theme.orange
        default:
            text = "A storm causes $2 million in damage. Your reserve covers it and services keep running. Some residents wished you'd spent that money earlier, but they're glad you didn't."
            color = Theme.green
        }
        return Card(tint: color) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Storm damage", systemImage: "cloud.bolt.rain.fill").font(.headline)
                Text(text).font(.subheadline)
            }
        }
    }
}
