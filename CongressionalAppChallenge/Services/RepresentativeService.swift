//
//  RepresentativeService.swift
//  CongressionalAppChallenge
//
//  Looks up a person's members of Congress using free public data:
//   - unitedstates/congress-legislators (current members, contact info)
//   - Census Geocoder (optional street address -> congressional district)
//   - zippopotam.us (ZIP -> state)
//  No API keys, no accounts. A street address is only sent to the Census
//  Geocoder for the lookup and is never stored.
//

import Foundation

struct Representative: Identifiable, Hashable {
    let id: String
    let name: String
    let chamber: String       // "Senator" or "Representative"
    let state: String
    let district: Int?
    let party: String
    let phone: String?
    let website: URL?
    let contactForm: URL?
    let photoURL: URL

    var title: String {
        if chamber == "Senator" { return "U.S. Senator" }
        if let district, district > 0 { return "U.S. Representative, District \(district)" }
        return "U.S. Representative (At-Large)"
    }
}

struct RepresentativeResult {
    var stateCode: String
    var senators: [Representative]
    var houseMembers: [Representative]
    var exactDistrict: Bool
    var note: String?
}

enum LookupError: LocalizedError {
    case badZip, zipNotFound, addressNotFound, network

    var errorDescription: String? {
        switch self {
        case .badZip: return "Enter a 5-digit ZIP code."
        case .zipNotFound: return "We couldn't find that ZIP code."
        case .addressNotFound: return "We couldn't match that address, so here are all House members for your state."
        case .network: return "Couldn't connect. Check your internet connection and try again."
        }
    }
}

actor RepresentativeService {
    static let shared = RepresentativeService()

    private struct Legislator: Decodable {
        struct ID: Decodable { let bioguide: String }
        struct Name: Decodable { let official_full: String?; let first: String; let last: String }
        struct Term: Decodable {
            let type: String
            let state: String
            let district: Int?
            let party: String
            let url: String?
            let phone: String?
            let contact_form: String?
        }
        let id: ID
        let name: Name
        let terms: [Term]
    }

    private var cache: [Representative]?

    func lookup(zip: String, street: String?) async throws -> RepresentativeResult {
        guard zip.count == 5, zip.allSatisfy(\.isNumber) else { throw LookupError.badZip }
        let all = try await loadAll()

        var state = try await stateCode(forZip: zip)
        var matchedDistrict: Int?
        var addressFailed = false

        if let street, !street.trimmingCharacters(in: .whitespaces).isEmpty {
            if let found = try? await self.district(forAddress: "\(street), \(zip)") {
                state = found.state
                matchedDistrict = found.district
            } else {
                addressFailed = true
            }
        }

        let senators = all.filter { $0.chamber == "Senator" && $0.state == state }
            .sorted { $0.name < $1.name }
        var house = all.filter { $0.chamber == "Representative" && $0.state == state }
            .sorted { ($0.district ?? 0) < ($1.district ?? 0) }
        if let matchedDistrict {
            let exact = house.filter { ($0.district ?? 0) == matchedDistrict }
            if !exact.isEmpty { house = exact }
        }
        return RepresentativeResult(stateCode: state, senators: senators, houseMembers: house,
                                    exactDistrict: matchedDistrict != nil && house.count == 1,
                                    note: addressFailed ? LookupError.addressNotFound.errorDescription : nil)
    }

    // MARK: Data sources

    private func loadAll() async throws -> [Representative] {
        if let cache { return cache }
        let url = URL(string: "https://unitedstates.github.io/congress-legislators/legislators-current.json")!
        let cacheFile = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("legislators-current.json")

        var data: Data
        do {
            let (fresh, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw LookupError.network }
            data = fresh
            try? data.write(to: cacheFile)
        } catch {
            // Offline: fall back to the last copy we saved.
            guard let stored = try? Data(contentsOf: cacheFile) else { throw LookupError.network }
            data = stored
        }

        let decoded = try JSONDecoder().decode([Legislator].self, from: data)
        let reps: [Representative] = decoded.compactMap { l in
            guard let term = l.terms.last else { return nil }
            let full = l.name.official_full ?? "\(l.name.first) \(l.name.last)"
            return Representative(
                id: l.id.bioguide,
                name: full,
                chamber: term.type == "sen" ? "Senator" : "Representative",
                state: term.state,
                district: term.district,
                party: term.party,
                phone: term.phone,
                website: term.url.flatMap(URL.init(string:)),
                contactForm: term.contact_form.flatMap(URL.init(string:)),
                photoURL: URL(string: "https://unitedstates.github.io/images/congress/225x275/\(l.id.bioguide).jpg")!
            )
        }
        cache = reps
        return reps
    }

    private func stateCode(forZip zip: String) async throws -> String {
        guard let url = URL(string: "https://api.zippopotam.us/us/\(zip)") else { throw LookupError.badZip }
        let data: Data, response: URLResponse
        do { (data, response) = try await URLSession.shared.data(from: url) } catch { throw LookupError.network }
        if (response as? HTTPURLResponse)?.statusCode == 404 { throw LookupError.zipNotFound }
        struct Zip: Decodable {
            struct Place: Decodable { let stateAbbreviation: String
                enum CodingKeys: String, CodingKey { case stateAbbreviation = "state abbreviation" } }
            let places: [Place]
        }
        guard let place = try? JSONDecoder().decode(Zip.self, from: data).places.first else { throw LookupError.zipNotFound }
        return place.stateAbbreviation
    }

    private func district(forAddress address: String) async throws -> (state: String, district: Int) {
        var comps = URLComponents(string: "https://geocoding.geo.census.gov/geocoder/geographies/onelineaddress")!
        comps.queryItems = [
            .init(name: "address", value: address),
            .init(name: "benchmark", value: "Public_AR_Current"),
            .init(name: "vintage", value: "Current_Current"),
            .init(name: "format", value: "json")
        ]
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let result = root["result"] as? [String: Any],
            let matches = result["addressMatches"] as? [[String: Any]],
            let geos = matches.first?["geographies"] as? [String: Any],
            let districtKey = geos.keys.first(where: { $0.contains("Congressional Districts") }),
            let district = (geos[districtKey] as? [[String: Any]])?.first,
            let stateAbbr = (geos["States"] as? [[String: Any]])?.first?["STUSAB"] as? String
        else { throw LookupError.addressNotFound }

        // Census uses non-numeric / 98+ base names for at-large districts and delegates.
        let base = district["BASENAME"] as? String ?? ""
        let number = Int(base) ?? 0
        return (stateAbbr, number >= 98 ? 0 : number)
    }
}
