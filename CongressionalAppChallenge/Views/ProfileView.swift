//
//  ProfileView.swift
//  CongressionalAppChallenge
//

import SwiftUI

struct ProfileView: View {
    @Environment(ProgressStore.self) private var progress
    @AppStorage("soundOn") private var soundOn = true
    @AppStorage("hapticsOn") private var hapticsOn = true
    @State private var confirmReset = false
    private let library = ContentLibrary.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    levelCard
                    Text("Badges").font(.title3.weight(.heavy))
                    badgeGrid
                    Text("Progress").font(.title3.weight(.heavy))
                    Card {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(library.units) { unit in
                                VStack(alignment: .leading, spacing: 6) {
                                    Label(unit.title, systemImage: unit.icon).font(.subheadline.weight(.bold))
                                    ChunkyProgressBar(value: progress.progress(for: unit), color: Theme.unitColor(unit.color), height: 12)
                                }
                            }
                        }
                    }
                    Text("Settings").font(.title3.weight(.heavy))
                    Card {
                        VStack(spacing: 4) {
                            Toggle(isOn: $soundOn) { Label("Sound effects", systemImage: "speaker.wave.2.fill") }
                                .onChange(of: soundOn) { _, on in if on { Feedback.play(.pop) } }
                            Divider()
                            Toggle(isOn: $hapticsOn) { Label("Haptics", systemImage: "hand.tap.fill") }
                                .onChange(of: hapticsOn) { _, on in if on { Feedback.play(.tap, haptic: .light) } }
                        }
                        .font(.subheadline.weight(.semibold))
                        .tint(Theme.green)
                    }
                    Text("About").font(.title3.weight(.heavy))
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("This app helps students understand how government works and how to take part in it. Lessons are nonpartisan and cite official sources such as Congress.gov, the National Archives, USA.gov, and Oyez.")
                                .font(.footnote)
                            Label("No account, no ads, no tracking. Your progress stays on this device. Only the representative lookup contacts public services.", systemImage: "lock.fill")
                                .font(.footnote.weight(.semibold))
                        }
                    }
                    Button("Reset all progress") { confirmReset = true }
                        .buttonStyle(PrimaryButtonStyle(color: Theme.red))
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Me")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Erase all progress on this device?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Erase progress", role: .destructive) { progress.resetAll() }
            }
        }
    }

    private var levelCard: some View {
        Card(tint: Theme.gold) {
            HStack(spacing: 14) {
                IconBadge(systemName: "star.fill", color: Theme.gold, size: 64)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Level \(progress.xp / 100 + 1)").font(.title.weight(.black))
                    Text("\(progress.xp) XP · \(progress.streak)-day streak").font(.subheadline).foregroundStyle(.secondary)
                    ChunkyProgressBar(value: Double(progress.xp % 100) / 100, color: Theme.gold, height: 12)
                }
            }
        }
    }

    private var badgeGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
            ForEach(progress.badges(in: library)) { badge in
                VStack(spacing: 8) {
                    IconBadge(systemName: badge.icon, color: badge.earned ? Theme.gold : Color.gray.opacity(0.5), size: 52)
                    Text(badge.title).font(.caption.weight(.heavy)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Theme.border, lineWidth: 2))
                .opacity(badge.earned ? 1 : 0.6)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(badge.title). \(badge.earned ? "Earned" : "Locked: \(badge.detail)")")
            }
        }
    }
}
