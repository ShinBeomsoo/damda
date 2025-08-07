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

    // 오늘 복습할 카드 목록
    var todayReviewCards: [Card] {
        let today = Calendar.current.startOfDay(for: Date())
        return cards.filter { card in
            guard let last = card.lastReviewedAt else { return true }
            let nextReviewDate = Calendar.current.date(byAdding: .day, value: Int(card.reviewInterval), to: last)!
            return nextReviewDate <= today
        }
    }

    // 복습 결과 기록 (SRS 알고리즘은 단순화)
    func review(card: Card, result: ReviewResult) {
        card.reviewCount += 1
        card.lastReviewedAt = Date()
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
        try? context.save()
        fetchCards()
    }

    enum ReviewResult {
        case success, fail, medium
    }
}
