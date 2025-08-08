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
    
    func testAddCard() async throws {
        let context = PersistenceController.shared.container.viewContext
        let cardManager = CardManagerObservable(context: context)
        
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
        let context = PersistenceController.shared.container.viewContext
        let cardManager = CardManagerObservable(context: context)
        
        // 카드 추가
        cardManager.addCard(question: "삭제할 카드", answer: "삭제할 답변")
        let initialCount = cardManager.cards.count
        
        // 마지막 카드 삭제
        if let lastCard = cardManager.cards.last {
            cardManager.deleteCard(card: lastCard)
            XCTAssertEqual(cardManager.cards.count, initialCount - 1)
        }
    }
    
    func testUpdateCard() async throws {
        let context = PersistenceController.shared.container.viewContext
        let cardManager = CardManagerObservable(context: context)
        
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
        let context = PersistenceController.shared.container.viewContext
        let cardManager = CardManagerObservable(context: context)
        
        // 카드 추가
        cardManager.addCard(question: "복습할 카드", answer: "복습할 답변")
        
        if let card = cardManager.cards.last {
            let initialReviewCount = card.reviewCount
            let initialSuccessCount = card.successCount
            let initialFailCount = card.failCount
            let initialInterval = card.reviewInterval
            
            // 성공으로 복습
            cardManager.review(card: card, result: .success)
            
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
        }
    }
    
    func testTodayReviewCards() async throws {
        let context = PersistenceController.shared.container.viewContext
        let cardManager = CardManagerObservable(context: context)
        
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
        let context = PersistenceController.shared.container.viewContext
        let cardManager = CardManagerObservable(context: context)
        
        // 카드 추가
        cardManager.addCard(question: "다양한 결과 테스트", answer: "다양한 결과 답변")
        
        if let card = cardManager.cards.last {
            let initialInterval = card.reviewInterval
            
            // 애매함으로 복습
            cardManager.review(card: card, result: .medium)
            XCTAssertEqual(card.reviewInterval, max(initialInterval, 2))
            
            // 성공으로 복습
            cardManager.review(card: card, result: .success)
            XCTAssertEqual(card.reviewInterval, min(card.reviewInterval * 2, 30))
            
            // 실패로 복습
            cardManager.review(card: card, result: .fail)
            XCTAssertEqual(card.reviewInterval, 1)
        }
    }
} 