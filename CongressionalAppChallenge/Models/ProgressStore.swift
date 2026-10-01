//
//  ProgressStore.swift
//  CongressionalAppChallenge
//
//  All progress lives on-device (UserDefaults). No account, no tracking.
//

import Foundation
import Observation

struct Badge: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let earned: Bool
}

@Observable
final class ProgressStore {
    struct Saved: Codable {
        var lessonScores: [String: Int] = [:]      // lessonID -> best correct answers
        var xp: Int = 0
        var streak: Int = 0
        var lastActiveDay: Date?
        var actions: Set<String> = []
        var simulations: Set<String> = []
        var zip: String = ""
        var dailyAnsweredDay: Date?
    }

    private(set) var saved: Saved
    private let key = "civaware.progress.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Saved.self, from: data) {
            saved = decoded
        } else {
            saved = Saved()
        }
        refreshStreakForToday()
    }

    var xp: Int { saved.xp }
    var streak: Int { saved.streak }
    var zip: String { saved.zip }
    var completedActionCount: Int { saved.actions.count }
    var completedLessonCount: Int { saved.lessonScores.count }

    func isCompleted(_ lesson: Lesson) -> Bool { saved.lessonScores[lesson.id] != nil }
    func bestScore(_ lesson: Lesson) -> Int? { saved.lessonScores[lesson.id] }
    func didAction(_ id: String) -> Bool { saved.actions.contains(id) }
    func didSimulation(_ id: String) -> Bool { saved.simulations.contains(id) }

    func progress(for unit: Unit) -> Double {
        guard !unit.lessons.isEmpty else { return 0 }
        return Double(unit.lessons.filter(isCompleted).count) / Double(unit.lessons.count)
    }

    func nextLesson(in library: ContentLibrary) -> Lesson? {
        library.allLessons.first { !isCompleted($0) }
    }

    // MARK: Mutations

    func completeLesson(_ lesson: Lesson, correct: Int) {
        let previous = saved.lessonScores[lesson.id]
        if previous == nil { saved.xp += 20 }
        if correct > (previous ?? -1) {
            saved.xp += max(0, correct - (previous ?? 0)) * 5
            saved.lessonScores[lesson.id] = correct
        }
        registerActivity()
    }

    func completeAction(_ id: String) {
        guard saved.actions.insert(id).inserted else { return }
        saved.xp += 30
        registerActivity()
    }

    func completeSimulation(_ id: String) {
        if saved.simulations.insert(id).inserted { saved.xp += 25 }
        registerActivity()
    }

    var answeredDailyToday: Bool {
        guard let day = saved.dailyAnsweredDay else { return false }
        return Calendar.current.isDateInToday(day)
    }

    func answerDaily(correct: Bool) {
        guard !answeredDailyToday else { return }
        saved.dailyAnsweredDay = .now
        if correct { saved.xp += 10 }
        registerActivity()
    }

    func setZip(_ zip: String) {
        saved.zip = zip
        persist()
    }

    func resetAll() {
        saved = Saved()
        persist()
    }

    // MARK: Streak

    private func refreshStreakForToday() {
        guard let last = saved.lastActiveDay else { return }
        let cal = Calendar.current
        let gap = cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: .now)).day ?? 0
        if gap > 1 { saved.streak = 0; persist() }
    }

    private func registerActivity() {
        let cal = Calendar.current
        if let last = saved.lastActiveDay {
            let gap = cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: .now)).day ?? 0
            if gap == 1 { saved.streak += 1 } else if gap > 1 { saved.streak = 1 }
            if saved.streak == 0 { saved.streak = 1 }
        } else {
            saved.streak = 1
        }
        saved.lastActiveDay = .now
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: Badges

    func badges(in library: ContentLibrary) -> [Badge] {
        let unitsDone = library.units.filter { progress(for: $0) >= 1 }.count
        return [
            Badge(id: "first", title: "First Steps", detail: "Finish your first lesson", icon: "flag.fill", earned: completedLessonCount >= 1),
            Badge(id: "streak3", title: "On a Roll", detail: "Reach a 3-day streak", icon: "flame.fill", earned: streak >= 3),
            Badge(id: "unit", title: "Unit Master", detail: "Complete a whole unit", icon: "rosette", earned: unitsDone >= 1),
            Badge(id: "sim", title: "Lawmaker", detail: "Finish Build a Bill", icon: "scroll.fill", earned: didSimulation("bill")),
            Badge(id: "budget", title: "City Planner", detail: "Balance the City Budget", icon: "building.2.fill", earned: didSimulation("budget")),
            Badge(id: "spin", title: "Fact Checker", detail: "Finish Spot the Spin", icon: "eye.fill", earned: didSimulation("spin")),
            Badge(id: "act", title: "Active Citizen", detail: "Complete a civic action", icon: "megaphone.fill", earned: completedActionCount >= 1),
            Badge(id: "all", title: "Civics Pro", detail: "Complete every unit", icon: "star.circle.fill", earned: !library.units.isEmpty && unitsDone == library.units.count)
        ]
    }
}
