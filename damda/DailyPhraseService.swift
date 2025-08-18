import Foundation

struct DailyPhrase: Codable, Equatable {
    let id: Int
    let en: String
    let ko: String
    let tags: [String]
    let level: String
}

enum DailyPhraseError: Error {
    case invalidURL
    case network(Error)
    case decoding(Error)
    case empty
}

enum DailyPhraseSelector {
    static func select(from phrases: [DailyPhrase], on date: Date, calendar: Calendar = .current) -> DailyPhrase? {
        guard !phrases.isEmpty else { return nil }
        let startOfDay = calendar.startOfDay(for: date)
        let dayNumber = Int(startOfDay.timeIntervalSince1970 / 86_400)
        let index = abs(dayNumber) % phrases.count
        return phrases[index]
    }

    static func selectTwo(from phrases: [DailyPhrase], on date: Date, calendar: Calendar = .current) -> [DailyPhrase] {
        guard !phrases.isEmpty else { return [] }
        if phrases.count == 1 {
            return [phrases[0]]
        }
        let startOfDay = calendar.startOfDay(for: date)
        let dayNumber = Int(startOfDay.timeIntervalSince1970 / 86_400)
        let count = phrases.count
        let firstIndex = (abs(dayNumber) % count)
        // A second deterministic index using a simple LCG-style mix, distinct from first
        var secondIndex = abs((dayNumber &* 1103515245 &+ 12345)) % count
        if secondIndex == firstIndex {
            secondIndex = (firstIndex + 1) % count
        }
        return [phrases[firstIndex], phrases[secondIndex]]
    }
}

protocol DailyPhraseProviding {
    func fetchPhrases(completion: @escaping (Result<[DailyPhrase], DailyPhraseError>) -> Void)
}

final class RemoteDailyPhraseProvider: DailyPhraseProviding {
    private let url: URL
    private let session: URLSession

    init(urlString: String, session: URLSession = .shared) throws {
        guard let url = URL(string: urlString) else { throw DailyPhraseError.invalidURL }
        self.url = url
        self.session = session
    }

    func fetchPhrases(completion: @escaping (Result<[DailyPhrase], DailyPhraseError>) -> Void) {
        let task = session.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(.network(error)))
                return
            }
            guard let data = data else {
                completion(.failure(.empty))
                return
            }
            do {
                let phrases = try JSONDecoder().decode([DailyPhrase].self, from: data)
                if phrases.isEmpty { completion(.failure(.empty)) } else { completion(.success(phrases)) }
            } catch {
                completion(.failure(.decoding(error)))
            }
        }
        task.resume()
    }
}

final class DailyPhraseCache {
    private let userDefaults: UserDefaults
    private let phrasesKey = "dailyPhrase.phrases"
    private let fetchedDayKey = "dailyPhrase.fetchedDay"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadCachedPhrases() -> [DailyPhrase]? {
        guard let data = userDefaults.data(forKey: phrasesKey) else { return nil }
        return try? JSONDecoder().decode([DailyPhrase].self, from: data)
    }

    func save(phrases: [DailyPhrase], day: Int) {
        guard let data = try? JSONEncoder().encode(phrases) else { return }
        userDefaults.set(data, forKey: phrasesKey)
        userDefaults.set(day, forKey: fetchedDayKey)
    }

    func lastFetchedDay() -> Int? {
        let day = userDefaults.integer(forKey: fetchedDayKey)
        return day == 0 ? nil : day
    }
}

final class DailyPhraseService {
    private let provider: DailyPhraseProviding
    private let cache: DailyPhraseCache
    private let calendar: Calendar

    init(provider: DailyPhraseProviding, cache: DailyPhraseCache = DailyPhraseCache(), calendar: Calendar = .current) {
        self.provider = provider
        self.cache = cache
        self.calendar = calendar
    }

    func phraseForToday(now: Date = Date(), completion: @escaping (DailyPhrase?) -> Void) {
        let dayNumber = Int(calendar.startOfDay(for: now).timeIntervalSince1970 / 86_400)

        if let lastDay = cache.lastFetchedDay(), lastDay == dayNumber, let cached = cache.loadCachedPhrases(), let p = DailyPhraseSelector.select(from: cached, on: now, calendar: calendar) {
            completion(p)
            return
        }

        provider.fetchPhrases { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let phrases):
                self.cache.save(phrases: phrases, day: dayNumber)
                let p = DailyPhraseSelector.select(from: phrases, on: now, calendar: self.calendar)
                completion(p)
            case .failure:
                if let cached = self.cache.loadCachedPhrases() {
                    let p = DailyPhraseSelector.select(from: cached, on: now, calendar: self.calendar)
                    completion(p)
                } else {
                    completion(nil)
                }
            }
        }
    }

    func phrasesForTodayPair(now: Date = Date(), completion: @escaping ([DailyPhrase]) -> Void) {
        let dayNumber = Int(calendar.startOfDay(for: now).timeIntervalSince1970 / 86_400)

        if let lastDay = cache.lastFetchedDay(), lastDay == dayNumber, let cached = cache.loadCachedPhrases() {
            completion(DailyPhraseSelector.selectTwo(from: cached, on: now, calendar: calendar))
            return
        }

        provider.fetchPhrases { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let phrases):
                self.cache.save(phrases: phrases, day: dayNumber)
                completion(DailyPhraseSelector.selectTwo(from: phrases, on: now, calendar: self.calendar))
            case .failure:
                if let cached = self.cache.loadCachedPhrases() {
                    completion(DailyPhraseSelector.selectTwo(from: cached, on: now, calendar: self.calendar))
                } else {
                    completion([])
                }
            }
        }
    }
}


