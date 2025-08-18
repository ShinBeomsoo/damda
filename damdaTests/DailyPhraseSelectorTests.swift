import XCTest
@testable import damda

final class DailyPhraseSelectorTests: XCTestCase {

    func testSameDateReturnsSamePhrase() {
        let phrases = samplePhrases(count: 10)
        let date = Date(timeIntervalSince1970: 1_700_000_000) // fixed
        let first = DailyPhraseSelector.select(from: phrases, on: date)
        let second = DailyPhraseSelector.select(from: phrases, on: date)
        XCTAssertEqual(first?.id, second?.id)
    }

    func testDifferentDatesLikelyReturnDifferentPhrases() {
        let phrases = samplePhrases(count: 10)
        let day1 = Date(timeIntervalSince1970: 1_700_000_000) // D
        let day2 = Date(timeIntervalSince1970: 1_700_000_000 + 86_400) // D+1
        let p1 = DailyPhraseSelector.select(from: phrases, on: day1)
        let p2 = DailyPhraseSelector.select(from: phrases, on: day2)
        XCTAssertNotEqual(p1?.id, p2?.id)
    }

    func testEmptyListReturnsNil() {
        let empty: [DailyPhrase] = []
        let result = DailyPhraseSelector.select(from: empty, on: Date())
        XCTAssertNil(result)
    }

    func testIndexWithinBounds() {
        let phrases = samplePhrases(count: 3)
        let dates: [Date] = [
            Date(timeIntervalSince1970: 0),
            Date(timeIntervalSince1970: 86_400),
            Date(timeIntervalSince1970: 2 * 86_400),
            Date(timeIntervalSince1970: 10 * 86_400)
        ]
        for d in dates {
            let p = DailyPhraseSelector.select(from: phrases, on: d)
            XCTAssertNotNil(p)
        }
    }

    func testSelectTwoDistinct() {
        let phrases = samplePhrases(count: 5)
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let pair = DailyPhraseSelector.selectTwo(from: phrases, on: date)
        XCTAssertTrue(pair.count >= 1)
        if pair.count == 2 {
            XCTAssertNotEqual(pair[0].id, pair[1].id)
        }
    }

    private func samplePhrases(count: Int) -> [DailyPhrase] {
        (1...count).map { i in
            DailyPhrase(id: i, en: "Sentence #\(i)", ko: "문장 #\(i)", tags: [], level: "A1")
        }
    }
}


