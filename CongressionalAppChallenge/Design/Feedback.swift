//
//  Feedback.swift
//  CongressionalAppChallenge
//
//  Sound effects and haptics. Every sound is synthesized (see
//  Docs/tools/make_sounds.py), so there are no licensing worries. Both are
//  user-toggleable, and sound mixes with other audio and respects the
//  silent switch.
//

import AVFoundation
import UIKit

enum SFX: String, CaseIterable {
    case tap, pop, correct, wrong, complete, sparkle, gavel, whoosh
}

enum Haptic { case light, success, warning, error }

@MainActor
enum Feedback {
    private static var players: [SFX: AVAudioPlayer] = [:]
    private static var sessionReady = false

    static var soundOn: Bool { UserDefaults.standard.object(forKey: "soundOn") as? Bool ?? true }
    static var hapticsOn: Bool { UserDefaults.standard.object(forKey: "hapticsOn") as? Bool ?? true }

    static func play(_ sfx: SFX, haptic: Haptic? = nil) {
        if soundOn { playSound(sfx) }
        if hapticsOn, let haptic { fire(haptic) }
    }

    private static func playSound(_ sfx: SFX) {
        prepareSession()
        if players[sfx] == nil,
           let url = Bundle.main.url(forResource: sfx.rawValue, withExtension: "wav"),
           let player = try? AVAudioPlayer(contentsOf: url) {
            player.prepareToPlay()
            players[sfx] = player
        }
        guard let player = players[sfx] else { return }
        player.currentTime = 0
        player.play()
    }

    private static func prepareSession() {
        guard !sessionReady else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        sessionReady = true
    }

    private static func fire(_ haptic: Haptic) {
        switch haptic {
        case .light: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error: UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
