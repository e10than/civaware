//
//  Content.swift
//  CongressionalAppChallenge
//
//  Lesson content is bundled JSON so lessons can be added or corrected
//  without touching any Swift code.
//

import Foundation

struct ContentLibrary: Decodable {
    let units: [Unit]
    let words: [Word]

    var allLessons: [Lesson] { units.flatMap(\.lessons) }

    func unit(for lesson: Lesson) -> Unit? {
        units.first { $0.lessons.contains { $0.id == lesson.id } }
    }

    static let shared: ContentLibrary = {
        guard let url = Bundle.main.url(forResource: "content", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let library = try? JSONDecoder().decode(ContentLibrary.self, from: data)
        else { return ContentLibrary(units: [], words: []) }
        return library
    }()
}

struct Unit: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
    let color: String
    let blurb: String
    let lessons: [Lesson]

    static func == (l: Unit, r: Unit) -> Bool { l.id == r.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct Lesson: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let minutes: Int
    let cards: [LessonCard]
    let quiz: [Question]
    let sources: [Source]
    let action: LessonAction?

    static func == (l: Lesson, r: Lesson) -> Bool { l.id == r.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct LessonCard: Decodable, Hashable {
    let heading: String
    let body: String
}

struct Question: Decodable, Hashable {
    let prompt: String
    let choices: [String]
    let answer: Int
    let explanation: String
}

struct Source: Decodable, Hashable {
    let title: String
    let url: String
}

struct LessonAction: Decodable, Hashable {
    let kind: String
    let title: String
    let detail: String
}

struct Word: Decodable, Hashable {
    let term: String
    let definition: String
}
