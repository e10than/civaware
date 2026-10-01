//
//  ActView.swift
//  CongressionalAppChallenge
//
//  Learning is only half the point. This tab connects students to their
//  real representatives and to concrete civic actions.
//

import SwiftUI

struct ActView: View {
    @Environment(ProgressStore.self) private var progress
    @Environment(\.openURL) private var openURL

    @State private var zip = ""
    @State private var street = ""
    @State private var isLoading = false
    @State private var result: RepresentativeResult?
    @State private var errorText: String?
    @State private var showComposer = false

    var body: some View {
        NavigationStack {
            List {
                repsSection
                actionsSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Act")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showComposer) {
                MessageComposerView(result: result, zip: zip)
            }
            .onAppear { if zip.isEmpty { zip = progress.zip } }
        }
    }

    // MARK: Representatives

    private var repsSection: some View {
        Section {
            TextField("ZIP code", text: $zip)
                .keyboardType(.numberPad)
                .textContentType(.postalCode)
            TextField("Street address (optional, for your exact House member)", text: $street)
                .textContentType(.streetAddressLine1)
            Button {
                Task { await search() }
            } label: {
                HStack {
                    Text("Find my representatives")
                    if isLoading { ProgressView().tint(.white) }
                }
            }
            .buttonStyle(PrimaryButtonStyle(color: Theme.green))
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
            .disabled(isLoading || zip.count != 5)

            if let errorText { Text(errorText).font(.footnote).foregroundStyle(Theme.orange) }

            if let result {
                if let note = result.note { Text(note).font(.footnote).foregroundStyle(Theme.orange) }
                ForEach(result.senators) { RepRow(rep: $0) }
                if !result.exactDistrict && result.houseMembers.count > 1 {
                    Text("Your ZIP may cover several districts. Add your street address above to find your exact House member.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(result.houseMembers) { RepRow(rep: $0) }
            }
        } header: {
            Label("Your representatives", systemImage: "person.3.fill").font(.headline.weight(.heavy)).foregroundStyle(.primary).textCase(nil)
        } footer: {
            Text("Lookups use free public services: the unitedstates/congress-legislators dataset, zippopotam.us (ZIP to state) and the U.S. Census Geocoder (address to district). Your ZIP and address are sent only to run the lookup, and the app never stores your address.")
        }
    }

    private func search() async {
        isLoading = true
        errorText = nil
        defer { isLoading = false }
        do {
            let found = try await RepresentativeService.shared.lookup(zip: zip, street: street)
            withAnimation { result = found }
            progress.setZip(zip)
            progress.completeAction("findReps")
            Feedback.play(.correct, haptic: .success)
        } catch {
            result = nil
            errorText = (error as? LookupError)?.errorDescription ?? "Something went wrong. Try again."
            Feedback.play(.wrong, haptic: .warning)
        }
    }

    // MARK: Actions

    private var actionsSection: some View {
        Section {
            ActionRow(id: "findReps", icon: "person.3.fill", title: "Find your representatives",
                      detail: "Look up who represents you above. This one completes itself.",
                      buttonTitle: nil, action: nil)
            ActionRow(id: "register", icon: "checkmark.seal.fill", title: "Check your voter registration",
                      detail: "Find your state's rules, deadlines, and pre-registration options on vote.gov.",
                      buttonTitle: "Open vote.gov") { openURL(URL(string: "https://vote.gov")!) }
            ActionRow(id: "contactRep", icon: "envelope.fill", title: "Write to a representative",
                      detail: "Draft a respectful message about an issue you care about.",
                      buttonTitle: "Draft a message") { showComposer = true }
            ActionRow(id: "meeting", icon: "person.2.wave.2.fill", title: "Watch a local meeting",
                      detail: "Search your city or school district name plus \"council meeting\" or \"board meeting\" and watch one.",
                      buttonTitle: "Search the web") {
                openURL(URL(string: "https://www.google.com/search?q=city+council+meeting+schedule+near+me")!)
            }
            ActionRow(id: "share", icon: "square.and.arrow.up.fill", title: "Teach a friend",
                      detail: "Share one thing you learned. Teaching is the best way to remember it.",
                      buttonTitle: nil, action: nil, shareText: "I'm learning how government really works with CivAware. Try a lesson!")
        } header: {
            Label("Civic actions", systemImage: "megaphone.fill").font(.headline.weight(.heavy)).foregroundStyle(.primary).textCase(nil)
        } footer: {
            Text("Every action earns XP. Tap the circle when you've done it.")
        }
    }
}

// MARK: - Rows

private struct RepRow: View {
    let rep: Representative
    @Environment(\.openURL) private var openURL

    private var partyLetter: String {
        switch rep.party {
        case "Democrat": return "D"
        case "Republican": return "R"
        default: return "I"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: rep.photoURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.crop.square.fill").resizable().scaledToFit().foregroundStyle(.secondary)
            }
            .frame(width: 56, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(rep.name) (\(partyLetter))").font(.headline.weight(.heavy))
                Text(rep.title).font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    if let phone = rep.phone, let url = URL(string: "tel:\(phone.filter { $0.isNumber })") {
                        Button { openURL(url) } label: { Label(phone, systemImage: "phone.fill") }
                    }
                    if let form = rep.contactForm ?? rep.website {
                        Button { openURL(form) } label: { Label("Contact", systemImage: "envelope") }
                    }
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ActionRow: View {
    @Environment(ProgressStore.self) private var progress
    let id: String
    let icon: String
    let title: String
    let detail: String
    let buttonTitle: String?
    let action: (() -> Void)?
    var shareText: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                if !progress.didAction(id) { Feedback.play(.sparkle, haptic: .success) }
                progress.completeAction(id)
            } label: {
                Image(systemName: progress.didAction(id) ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(progress.didAction(id) ? Theme.green : .secondary)
                    .symbolEffect(.bounce, value: progress.didAction(id))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(progress.didAction(id) ? "Completed: \(title)" : "Mark \(title) as done")

            VStack(alignment: .leading, spacing: 4) {
                Label(title, systemImage: icon).font(.headline.weight(.heavy))
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
                if let buttonTitle, let action {
                    Button(buttonTitle, action: action).buttonStyle(.borderedProminent).tint(Theme.blue).padding(.top, 2)
                }
                if let shareText {
                    ShareLink(item: shareText) { Label("Share", systemImage: "square.and.arrow.up") }
                        .buttonStyle(.bordered).padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Message composer

struct MessageComposerView: View {
    let result: RepresentativeResult?
    let zip: String

    @Environment(ProgressStore.self) private var progress
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var name = ""
    @State private var city = ""
    @State private var issue = ""
    @State private var why = ""
    @State private var ask = ""
    @State private var chosenID: String?
    @State private var copied = false

    private var reps: [Representative] { (result?.senators ?? []) + (result?.houseMembers ?? []) }
    private var chosen: Representative? { reps.first { $0.id == chosenID } ?? reps.first }

    private var draft: String {
        let salutation = chosen.map { "Dear \($0.chamber == "Senator" ? "Senator" : "Representative") \($0.name.split(separator: " ").last.map(String.init) ?? $0.name)," } ?? "Dear Representative,"
        let who = name.isEmpty ? "[your name]" : name
        let place = city.isEmpty ? "[your town]" : city
        return """
        \(salutation)

        My name is \(who) and I am a student in \(place). I am one of your constituents, and I am writing about \(issue.isEmpty ? "[an issue you care about]" : issue).

        \(why.isEmpty ? "[Explain in a sentence or two why this matters to you or your community.]" : why)

        I respectfully ask that you \(ask.isEmpty ? "[what you want them to do, such as support a bill or answer a question]" : ask).

        Thank you for your time and for your service.

        Sincerely,
        \(who)
        \(zip)
        """
    }

    var body: some View {
        NavigationStack {
            Form {
                if reps.isEmpty {
                    Section { Text("Find your representatives first (use the ZIP code box on the Act tab), then come back to pick who to write to.").foregroundStyle(.secondary) }
                } else {
                    Section("Write to") {
                        Picker("Representative", selection: Binding(get: { chosen?.id ?? "" }, set: { chosenID = $0 })) {
                            ForEach(reps) { Text($0.name).tag($0.id) }
                        }
                    }
                }
                Section("About you") {
                    TextField("Your first name", text: $name)
                    TextField("Your town", text: $city)
                }
                Section("Your message") {
                    TextField("Issue (e.g. school lunch funding)", text: $issue)
                    TextField("Why it matters", text: $why, axis: .vertical).lineLimit(2...5)
                    TextField("What you're asking for", text: $ask, axis: .vertical).lineLimit(2...4)
                }
                Section("Preview") {
                    Text(draft).font(.footnote)
                    Button(copied ? "Copied!" : "Copy message") {
                        UIPasteboard.general.string = draft
                        copied = true
                        progress.completeAction("contactRep")
                    }
                    if let form = chosen?.contactForm ?? chosen?.website {
                        Button("Open \(chosen?.name ?? "their") contact page") {
                            UIPasteboard.general.string = draft
                            progress.completeAction("contactRep")
                            openURL(form)
                        }
                    }
                }
                Section {
                    Text("Tips: Be respectful, be specific, and keep it short. Members of Congress usually accept messages through a form on their website, so paste your message there. Read it over before you send it. You are speaking for yourself.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Write a message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}
