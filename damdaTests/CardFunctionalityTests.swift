//
//  CardFunctionalityTests.swift
//  damdaTests
//
//  Created by SHIN BEOMSOO on 8/8/25.
//

import XCTest
import CoreData
@testable import damda

final class CardFunctionalityTests: XCTestCase {
    private func makeInMemoryContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "damda")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
        return container.viewContext
    }
    
    func testAddCard() async throws {
        let context = makeInMemoryContext()
        let cardManager = CardManagerObservable(context: context, useSM2Scheduling: false)
        
        // 초기 카드 수 확인
        let initialCount = cardManager.cards.count
        
        // 카드 추가
        cardManager.addCard(question: "테스트 질문", answer: "테스트 답변")
        
        // 카드가 추가되었는지 확인
        XCTAssertEqual(cardManager.cards.count, initialCount + 1)
        
        // 추가된 카드의 내용 확인
        let addedCard = cardManager.cards.last
        XCTAssertEqual(addedCard?.question, "테스트 질문")
        XCTAssertEqual(addedCard?.answer, "테스트 답변")
        XCTAssertEqual(addedCard?.reviewInterval, 1)
        XCTAssertEqual(addedCard?.reviewCount, 0)
    }
    
    func testDeleteCard() async throws {
        let context = makeInMemoryContext()
        let cardManager = CardManagerObservable(context: context, useSM2Scheduling: false)
        
        // 카드 추가
        cardManager.addCard(question: "삭제할 카드", answer: "삭제할 답변")
        let initialCount = cardManager.cards.count
        
        // 마지막 카드 삭제
        guard let lastCard = cardManager.cards.last else {
            XCTFail("추가된 카드를 찾지 못했습니다.")
            return
        }
        let deletedCardId = lastCard.id
        cardManager.deleteCard(card: lastCard)
        
        // 카운트 감소 확인
        XCTAssertEqual(cardManager.cards.count, initialCount - 1)
        
        // 실제로 삭제되었는지 페치로 확인
        let fetch: NSFetchRequest<Card> = Card.fetchRequest()
        fetch.predicate = NSPredicate(format: "id == %lld", deletedCardId)
        let remaining = try context.fetch(fetch)
        XCTAssertTrue(remaining.isEmpty)
    }
    
    func testUpdateCard() async throws {
        let context = makeInMemoryContext()
        let cardManager = CardManagerObservable(context: context, useSM2Scheduling: false)
        
        // 카드 추가
        cardManager.addCard(question: "원본 질문", answer: "원본 답변")
        
        // 카드 업데이트
        if let card = cardManager.cards.last {
            cardManager.updateCard(card: card, newQuestion: "수정된 질문", newAnswer: "수정된 답변")
            
            // 업데이트 확인
            XCTAssertEqual(card.question, "수정된 질문")
            XCTAssertEqual(card.answer, "수정된 답변")
        }
    }
    
    func testReviewCard() async throws {
        let context = makeInMemoryContext()
        let cardManager = CardManagerObservable(context: context, useSM2Scheduling: false)
        
        // 카드 추가
        cardManager.addCard(question: "복습할 카드", answer: "복습할 답변")
        
        if let card = cardManager.cards.last {
            let initialReviewCount = card.reviewCount
            let initialSuccessCount = card.successCount
            let initialFailCount = card.failCount
            let initialInterval = card.reviewInterval
            
            // 성공으로 복습
            cardManager.review(card: card, result: .success)
            let afterSuccessInterval = card.reviewInterval
            
            // 복습 결과 확인
            XCTAssertEqual(card.reviewCount, initialReviewCount + 1)
            XCTAssertEqual(card.successCount, initialSuccessCount + 1)
            XCTAssertEqual(card.failCount, initialFailCount)
            XCTAssertEqual(card.reviewInterval, min(initialInterval * 2, 30))
            XCTAssertNotNil(card.lastReviewedAt)
            
            // 실패로 복습
            cardManager.review(card: card, result: .fail)
            
            // 실패 결과 확인
            XCTAssertEqual(card.reviewCount, initialReviewCount + 2)
            XCTAssertEqual(card.successCount, initialSuccessCount + 1)
            XCTAssertEqual(card.failCount, initialFailCount + 1)
            XCTAssertEqual(card.reviewInterval, 1)
            // 단순 규칙 유지 확인(성공 시 2배가 실제로 적용되었는지 추가 검증)
            XCTAssertEqual(afterSuccessInterval, min(initialInterval * 2, 30))
        }
    }
    
    func testTodayReviewCards() async throws {
        let context = makeInMemoryContext()
        let cardManager = CardManagerObservable(context: context, useSM2Scheduling: false)
        
        // 카드 추가
        cardManager.addCard(question: "오늘 복습할 카드", answer: "오늘 복습할 답변")
        
        // 오늘 복습할 카드 목록 확인
        let todayCards = cardManager.todayReviewCards
        XCTAssertGreaterThan(todayCards.count, 0)
        
        // 새로 추가된 카드가 오늘 복습 목록에 포함되어 있는지 확인
        let hasNewCard = todayCards.contains { card in
            card.question == "오늘 복습할 카드"
        }
        XCTAssertTrue(hasNewCard)
    }
    
    func testCardReviewWithDifferentResults() async throws {
        let context = makeInMemoryContext()
        let cardManager = CardManagerObservable(context: context, useSM2Scheduling: false)
        
        // 카드 추가
        cardManager.addCard(question: "다양한 결과 테스트", answer: "다양한 결과 답변")
        
        if let card = cardManager.cards.last {
            let initialInterval = card.reviewInterval
            
            // 애매함으로 복습
            cardManager.review(card: card, result: .medium)
            XCTAssertEqual(card.reviewInterval, max(initialInterval, 2))
            
            // 성공으로 복습 (현재 간격의 2배가 되어야 하므로, 호출 전 값을 기준으로 기대값 계산)
            let beforeSuccess = card.reviewInterval
            cardManager.review(card: card, result: .success)
            XCTAssertEqual(card.reviewInterval, min(beforeSuccess * 2, 30))
            
            // 실패로 복습
            cardManager.review(card: card, result: .fail)
            XCTAssertEqual(card.reviewInterval, 1)
        }
    }
} 