import XCTest
@testable import damda

final class DailyPhraseServiceTests: XCTestCase {

    func testReturnsCachedWhenSameDay() {
        let phrases = [DailyPhrase(id: 1, en: "A", ko: "가", tags: [], level: "A1")]
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let cal = Calendar(identifier: .gregorian)
        let dayNumber = Int(cal.startOfDay(for: now).timeIntervalSince1970 / 86_400)

        let cache = DailyPhraseCache(userDefaults: UserDefaults(suiteName: "DailyPhraseTests")!)
        UserDefaults(suiteName: "DailyPhraseTests")!.removePersistentDomain(forName: "DailyPhraseTests")
        cache.save(phrases: phrases, day: dayNumber)

        let provider = StubProvider(result: .failure(.empty))
        let service = DailyPhraseService(provider: provider, cache: cache, calendar: cal)

        let exp = expectation(description: "phrase")
        service.phraseForToday(now: now) { phrase in
            XCTAssertEqual(phrase?.id, 1)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func testFetchesAndCachesOnNewDay() {
        let phrases = [DailyPhrase(id: 2, en: "B", ko: "나", tags: [], level: "A1")]
        let day1 = Date(timeIntervalSince1970: 1_700_000_000)
        let day2 = Date(timeIntervalSince1970: 1_700_000_000 + 86_400)
        let cal = Calendar(identifier: .gregorian)

        let ud = UserDefaults(suiteName: "DailyPhraseTests2")!
        ud.removePersistentDomain(forName: "DailyPhraseTests2")
        let cache = DailyPhraseCache(userDefaults: ud)

        let provider = StubProvider(result: .success(phrases))
        let service = DailyPhraseService(provider: provider, cache: cache, calendar: cal)

        let exp1 = expectation(description: "day1")
        service.phraseForToday(now: day1) { phrase in
            // No cache yet, provider success chooses a phrase
            XCTAssertNotNil(phrase)
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 1.0)

        let exp2 = expectation(description: "day2")
        service.phraseForToday(now: day2) { phrase in
            XCTAssertNotNil(phrase)
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: 1.0)
    }

    func testFallbackToCacheOnNetworkFailure() {
        let phrases = [DailyPhrase(id: 3, en: "C", ko: "다", tags: [], level: "A1")]
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let cal = Calendar(identifier: .gregorian)
        let dayNumber = Int(cal.startOfDay(for: now).timeIntervalSince1970 / 86_400)

        let ud = UserDefaults(suiteName: "DailyPhraseTests3")!
        ud.removePersistentDomain(forName: "DailyPhraseTests3")
        let cache = DailyPhraseCache(userDefaults: ud)
        cache.save(phrases: phrases, day: dayNumber)

        let provider = StubProvider(result: .failure(.network(NSError(domain: "test", code: -1))))
        let service = DailyPhraseService(provider: provider, cache: cache, calendar: cal)

        let exp = expectation(description: "fallback")
        service.phraseForToday(now: now) { phrase in
            XCTAssertEqual(phrase?.id, 3)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Stubs
    private struct StubProvider: DailyPhraseProviding {
        let result: Result<[DailyPhrase], DailyPhraseError>
        func fetchPhrases(completion: @escaping (Result<[DailyPhrase], DailyPhraseError>) -> Void) {
            DispatchQueue.global().async {
                completion(self.result)
            }
        }
    }
}


