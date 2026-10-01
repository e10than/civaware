//
//  ContentView.swift
//  CongressionalAppChallenge
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house.fill", value: 0) { HomeView(goTo: { selection = $0 }) }
            Tab("Learn", systemImage: "map.fill", value: 1) { LearnView() }
            Tab("Simulate", systemImage: "gamecontroller.fill", value: 2) { SimulateView() }
            Tab("Act", systemImage: "megaphone.fill", value: 3) { ActView() }
            Tab("Me", systemImage: "person.crop.circle.fill", value: 4) { ProfileView() }
        }
        .fontDesign(.rounded)
        .onChange(of: selection) { _, _ in Feedback.play(.pop, haptic: .light) }
    }
}

#Preview {
    ContentView().environment(ProgressStore())
}
