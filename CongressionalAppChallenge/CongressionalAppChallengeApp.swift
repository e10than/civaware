//
//  CongressionalAppChallengeApp.swift
//  CongressionalAppChallenge
//
//  Created by Ethan Lee on 9/29/26.
//

import SwiftUI

@main
struct CongressionalAppChallengeApp: App {
    @State private var progress = ProgressStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(progress)
                .tint(Theme.accent)
        }
    }
}
