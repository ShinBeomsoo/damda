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
    private let context: NSManagedObjectContext
    private let defaults = UserDefaults.standard
    private let useSM2Scheduling = true

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchCards()
    }

    func fetchCards() {
        let fetchRequest: NSFetchRequest<Card> = Card.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        if let results = try? context.fetch(fetchRequest) {
            cards = results
        }
    }

    func addCard(question: String, answer: String) {
        let card = Card(context: context)
        card.id = Int64(Date().timeIntervalSince1970 * 1000)
        card.question = question
        card.answer = answer
        card.createdAt = Date()
        card.reviewInterval = 1
        card.reviewCount = 0
        card.successCount = 0
        card.failCount = 0
        try? context.save()
        // Initialize SM-2 state in persistent storage (UserDefaults)
        initializeSM2StateIfNeeded(for: card)
        fetchCards()
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

    // 오늘 복습할 카드 목록 (dueDate 기반)
    var todayReviewCards: [Card] {
        let today = Calendar.current.startOfDay(for: Date())
        return cards.filter { card in
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
        guard let last = card.lastReviewedAt else { return nil }
        return Calendar.current.date(byAdding: .day, value: Int(card.reviewInterval), to: last)
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
        let medLabel = naturalDaysString(days: med)
        let succLabel = naturalDaysString(days: succ)
        let baseTip = "SM-2 기준 · 현재 EF: \(String(format: "%.2f", state.easeFactor)) · 반복: \(state.repetitionCount) · 현 간격: \(current)일"
        let failTip = baseTip + "\n결과: 모름 → 다음 간격 \(fail)일"
        let medTip  = baseTip + "\n결과: 애매함 → 다음 간격 \(med)일"
        let succTip = baseTip + "\n결과: 알고 있음 → 다음 간격 \(succ)일"
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
