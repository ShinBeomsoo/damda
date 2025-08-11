//
//  CardManagerObservable.swift
//  damda
//
//  Created by SHIN BEOMSOO on 8/7/25.
//

import Foundation
import CoreData
import Combine

class CardManagerObservable: ObservableObject {
    @Published var cards: [Card] = []
    @Published var decks: [NSManagedObject] = []
    @Published var selectedDeckId: Int64? = nil
    private let context: NSManagedObjectContext
    private let defaults = UserDefaults.standard
    private let useSM2Scheduling = true

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchCards()
        fetchDecks()
    }

    func fetchCards() {
        let fetchRequest: NSFetchRequest<Card> = Card.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        if let results = try? context.fetch(fetchRequest) {
            cards = results
        }
    }

    func fetchDecks() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Deck")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        if let results = try? context.fetch(request) {
            decks = results
        }
    }

    // MARK: - Helpers
    private func deckIdValue(of card: Card) -> Int64? {
        if let num = card.value(forKey: "deckId") as? NSNumber {
            return num.int64Value
        }
        return card.value(forKey: "deckId") as? Int64
    }

    private func deckIdValue(of deck: NSManagedObject) -> Int64? {
        if let num = deck.value(forKey: "id") as? NSNumber { return num.int64Value }
        return deck.value(forKey: "id") as? Int64
    }

    func deckName(for card: Card) -> String? {
        guard let did = deckIdValue(of: card) else { return nil }
        if let deck = decks.first(where: { deckIdValue(of: $0) == did }) {
            return deck.value(forKey: "name") as? String
        }
        return nil
    }

    func addCard(question: String, answer: String, deckId: Int64? = nil) {
        let card = Card(context: context)
        card.id = Int64(Date().timeIntervalSince1970 * 1000)
        card.question = question
        card.answer = answer
        card.createdAt = Date()
        card.reviewInterval = 1
        card.reviewCount = 0
        card.successCount = 0
        card.failCount = 0
        // 우선순위: 전달받은 deckId가 있으면 사용, 없으면 현재 선택 덱 사용
        let appliedDeckId = deckId ?? selectedDeckId
        if let deckId = appliedDeckId {
            card.setValue(NSNumber(value: deckId), forKey: "deckId")
        }
        try? context.save()
        // Initialize SM-2 state in persistent storage (UserDefaults)
        initializeSM2StateIfNeeded(for: card)
        fetchCards()
    }

    // MARK: - Deck CRUD
    func addDeck(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let entity = NSEntityDescription.entity(forEntityName: "Deck", in: context) else { return }
        let deck = NSManagedObject(entity: entity, insertInto: context)
        deck.setValue(Int64(Date().timeIntervalSince1970 * 1000), forKey: "id")
        deck.setValue(trimmed, forKey: "name")
        deck.setValue(Date(), forKey: "createdAt")
        try? context.save()
        fetchDecks()
    }

    func renameDeck(id: Int64, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let deck = decks.first(where: { deckIdValue(of: $0) == id }) {
            deck.setValue(trimmed, forKey: "name")
            try? context.save()
            fetchDecks()
            DispatchQueue.main.async { self.objectWillChange.send() }
        }
    }

    // v1: 삭제 제한 또는 모든 카드 deckId=nil 처리
    func deleteDeck(id: Int64) {
        guard let deck = decks.first(where: { deckIdValue(of: $0) == id }) else { return }
        // 카드 일괄 해제
        let affected = cards.filter { deckIdValue(of: $0) == id }
        affected.forEach { card in
            card.setValue(nil, forKey: "deckId")
        }
        context.delete(deck)
        try? context.save()
        fetchDecks()
        fetchCards()
        if selectedDeckId == id { selectedDeckId = nil }
    }

    // MARK: - Deck assignment
    func setDeck(card: Card, deckId: Int64?) {
        if let deckId { card.setValue(NSNumber(value: deckId), forKey: "deckId") } else { card.setValue(nil, forKey: "deckId") }
        try? context.save()
        // Fetch to refresh snapshots so filtered list updates immediately
        fetchCards()
        DispatchQueue.main.async { self.objectWillChange.send() }
    }

    func clearDeck(card: Card) { setDeck(card: card, deckId: nil) }

    var cardsForSelectedDeck: [Card] {
        guard let deckId = selectedDeckId else { return cards }
        return cards.filter { deckIdValue(of: $0) == deckId }
    }

    func deleteCard(card: Card) {
        context.delete(card)
        try? context.save()
        fetchCards()
    }

    func updateCard(card: Card, newQuestion: String, newAnswer: String) {
        card.question = newQuestion
        card.answer = newAnswer
        try? context.save()
        fetchCards()
    }

    // 오늘 복습할 카드 목록 (선택 덱 + dueDate 기반)
    var todayReviewCards: [Card] {
        let today = Calendar.current.startOfDay(for: Date())
        let base = cardsForSelectedDeck
        return base.filter { card in
            guard let due = dueDate(for: card) else { return true }
            return due <= today
        }
    }

    // 복습 결과 기록 (SM-2 기본 적용; 필요 시 기존 규칙 유지 가능)
    func review(card: Card, result: ReviewResult) {
        card.reviewCount += 1
        card.lastReviewedAt = Date()

        if useSM2Scheduling {
            // Map result to SM-2 quality
            let q: Int
            switch result {
            case .fail: q = 2
            case .medium: q = 3
            case .success: q = 5
            }

            // Load current SM-2 state
            var state = loadSM2State(for: card)
            state.intervalDays = Int(card.reviewInterval)
            // Review via SM-2
            let next = SM2Scheduler.review(state: state, quality: q)
            // Persist next state
            saveSM2State(for: card, state: next)

            // Reflect to Core Data fields used by UI
            switch result {
            case .success:
                card.successCount += 1
            case .fail:
                card.failCount += 1
            case .medium:
                break
            }
            card.reviewInterval = Int64(next.intervalDays)

            // Compute and persist next dueDate if attribute exists
            if let nextDue = computeDueDate(base: card.lastReviewedAt ?? Date(), days: next.intervalDays) {
                persistDueDateIfSupported(card: card, due: nextDue)
            }
        } else {
            // 기존 단순 규칙
            switch result {
            case .success:
                card.successCount += 1
                card.reviewInterval = min(card.reviewInterval * 2, 30)
            case .fail:
                card.failCount += 1
                card.reviewInterval = 1
            case .medium:
                card.reviewInterval = max(card.reviewInterval, 2)
            }

            // Compute and persist next dueDate if attribute exists
            if let nextDue = computeDueDate(base: card.lastReviewedAt ?? Date(), days: Int(card.reviewInterval)) {
                persistDueDateIfSupported(card: card, due: nextDue)
            }
        }

        try? context.save()
        fetchCards()
    }

    enum ReviewResult {
        case success, fail, medium
    }

    // MARK: - Preview intervals (for UI)
    func previewIntervals(for card: Card) -> (fail: Int, medium: Int, success: Int) {
        let current = Int(card.reviewInterval)
        if useSM2Scheduling {
            var state = loadSM2State(for: card)
            state.intervalDays = current
            let failNext = SM2Scheduler.review(state: state, quality: 2).intervalDays
            let medNext = SM2Scheduler.review(state: state, quality: 3).intervalDays
            let succNext = SM2Scheduler.review(state: state, quality: 5).intervalDays
            return (failNext, medNext, succNext)
        } else {
            let failNext = 1
            let medNext = max(current, 2)
            let succNext = min(current * 2, 30)
            return (failNext, medNext, succNext)
        }
    }

    // MARK: - Natural language helpers / Due date
    func dueDate(for card: Card) -> Date? {
        // Prefer persisted dueDate attribute if available
        if card.entity.attributesByName["dueDate"] != nil {
            if let persisted = card.value(forKey: "dueDate") as? Date {
                return persisted
            }
        }
        // Fallback: compute from lastReviewedAt + reviewInterval
        guard let last = card.lastReviewedAt else { return nil }
        return Calendar.current.date(byAdding: .day, value: Int(card.reviewInterval), to: last)
    }

    private func computeDueDate(base: Date, days: Int) -> Date? {
        Calendar.current.date(byAdding: .day, value: max(0, days), to: Calendar.current.startOfDay(for: base))
    }

    private func persistDueDateIfSupported(card: Card, due: Date) {
        guard card.entity.attributesByName["dueDate"] != nil else { return }
        card.setValue(due, forKey: "dueDate")
    }

    /// 오늘/내일/N일 뒤 포맷으로 변환
    func naturalDaysString(days: Int) -> String {
        switch days {
        case ..<0: return "오늘"
        case 0: return "오늘"
        case 1: return "내일"
        default: return "\(days)일 뒤"
        }
    }

    /// 카드의 다음 복습까지 남은 기간을 자연어로 반환
    func naturalDueLabel(for card: Card) -> String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let due = dueDate(for: card) else { return "오늘" }
        let dueDay = cal.startOfDay(for: due)
        let comps = cal.dateComponents([.day], from: today, to: dueDay)
        let days = max(0, comps.day ?? 0)
        return naturalDaysString(days: days)
    }

    func formattedDateLabel(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M/d(E)"
        return formatter.string(from: date)
    }

    func approxRelativeString(days: Int) -> String {
        if days <= 0 { return "오늘" }
        return "약 \(days)일 뒤"
    }

    struct PreviewInfo {
        let days: Int
        let label: String   // 자연어 라벨(오늘/내일/N일 뒤)
        let tooltip: String // 계산 근거 설명
    }

    /// 버튼별(모름/애매함/알고 있음) 다음 간격 미리보기 + 툴팁
    func previewInfos(for card: Card) -> (fail: PreviewInfo, medium: PreviewInfo, success: PreviewInfo) {
        let current = Int(card.reviewInterval)
        let state = loadSM2State(for: card)
        let (fail, med, succ) = previewIntervals(for: card)
        let failLabel = naturalDaysString(days: fail)
        let medLabel  = naturalDaysString(days: med)
        let succLabel = naturalDaysString(days: succ)
        let baseTip = "SM-2 기준 · 현재 EF: \(String(format: "%.2f", state.easeFactor)) · 반복: \(state.repetitionCount) · 현 간격: \(current)일"
        let failTip = baseTip + "\n결과: 모름 → 다음 간격 \(fail)일 · " + approxRelativeString(days: fail)
        let medTip  = baseTip + "\n결과: 애매함 → 다음 간격 \(med)일 · " + approxRelativeString(days: med)
        let succTip = baseTip + "\n결과: 알고 있음 → 다음 간격 \(succ)일 · " + approxRelativeString(days: succ)
        return (
            PreviewInfo(days: fail, label: failLabel, tooltip: failTip),
            PreviewInfo(days: med,  label: medLabel,  tooltip: medTip),
            PreviewInfo(days: succ, label: succLabel, tooltip: succTip)
        )
    }

    // MARK: - SM-2 persistence (UserDefaults)
    private func initializeSM2StateIfNeeded(for card: Card) {
        let keyEF = sm2Key(for: card, suffix: "ef")
        if defaults.object(forKey: keyEF) == nil {
            defaults.set(2.5, forKey: keyEF)
            defaults.set(0, forKey: sm2Key(for: card, suffix: "n"))
            defaults.set(0, forKey: sm2Key(for: card, suffix: "l"))
        }
    }

    private func loadSM2State(for: Card) -> SM2State {
        let ef = defaults.double(forKey: sm2Key(for: `for`, suffix: "ef"))
        let n = defaults.integer(forKey: sm2Key(for: `for`, suffix: "n"))
        let l = defaults.integer(forKey: sm2Key(for: `for`, suffix: "l"))
        // 기본값 보정
        let ease = ef == 0 ? 2.5 : ef
        return SM2State(easeFactor: ease, intervalDays: 0, repetitionCount: n, lapseCount: l)
    }

    private func saveSM2State(for: Card, state: SM2State) {
        defaults.set(state.easeFactor, forKey: sm2Key(for: `for`, suffix: "ef"))
        defaults.set(state.repetitionCount, forKey: sm2Key(for: `for`, suffix: "n"))
        defaults.set(state.lapseCount, forKey: sm2Key(for: `for`, suffix: "l"))
    }

    private func sm2Key(for card: Card, suffix: String) -> String {
        let idString: String
        if let objectURI = card.objectID.uriRepresentation().absoluteString as String? {
            idString = objectURI
        } else {
            idString = String(card.id)
        }
        return "sm2.card.\(idString).\(suffix)"
    }
}
