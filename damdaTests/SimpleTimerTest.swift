//
//  SimpleTimerTest.swift
//  damdaTests
//
//  Created by SHIN BEOMSOO on 8/8/25.
//

import XCTest
import CoreData
@testable import damda

final class SimpleTimerTest: XCTestCase {
    
    func testTimerBasicFunctionality() async throws {
        let context = PersistenceController.shared.container.viewContext
        let timerManager = TimerManagerObservable(context: context)
        
        // 1. 초기 상태 확인
        print("=== 초기 상태 ===")
        print("currentSession: \(timerManager.currentSession?.rawValue ?? "nil")")
        print("elapsedSeconds: \(timerManager.elapsedSeconds)")
        
        // 2. 타이머 시작
        print("=== 타이머 시작 ===")
        timerManager.start(session: .morning)
        print("currentSession: \(timerManager.currentSession?.rawValue ?? "nil")")
        print("elapsedSeconds: \(timerManager.elapsedSeconds)")
        
        // 3. 잠시 대기
        print("=== 1초 대기 ===")
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("elapsedSeconds: \(timerManager.elapsedSeconds)")
        
        // 4. 타이머 정지
        print("=== 타이머 정지 ===")
        timerManager.pause()
        print("currentSession: \(timerManager.currentSession?.rawValue ?? "nil")")
        print("elapsedSeconds: \(timerManager.elapsedSeconds)")
        
        // 5. 리셋
        print("=== 타이머 리셋 ===")
        timerManager.reset()
        print("currentSession: \(timerManager.currentSession?.rawValue ?? "nil")")
        print("elapsedSeconds: \(timerManager.elapsedSeconds)")
        
        // 기본적인 검증
        XCTAssertNil(timerManager.currentSession)
        XCTAssertEqual(timerManager.elapsedSeconds[.morning], 0)
        XCTAssertEqual(timerManager.elapsedSeconds[.afternoon], 0)
        XCTAssertEqual(timerManager.elapsedSeconds[.evening], 0)
    }
    
    func testCardBasicFunctionality() async throws {
        let context = PersistenceController.shared.container.viewContext
        let cardManager = CardManagerObservable(context: context)
        
        // 1. 초기 상태 확인
        print("=== 초기 카드 상태 ===")
        print("cards count: \(cardManager.cards.count)")
        
        // 2. 카드 추가
        print("=== 카드 추가 ===")
        cardManager.addCard(question: "테스트 질문", answer: "테스트 답변")
        print("cards count: \(cardManager.cards.count)")
        
        // 3. 추가된 카드 확인
        if let lastCard = cardManager.cards.last {
            print("추가된 카드: \(lastCard.question ?? "nil")")
            print("카드 답변: \(lastCard.answer ?? "nil")")
            
            // 4. 카드 복습
            print("=== 카드 복습 ===")
            cardManager.review(card: lastCard, result: .success)
            print("복습 후 reviewCount: \(lastCard.reviewCount)")
            print("복습 후 successCount: \(lastCard.successCount)")
            print("복습 후 reviewInterval: \(lastCard.reviewInterval)")
        }
        
        // 기본적인 검증
        XCTAssertGreaterThan(cardManager.cards.count, 0)
    }
} 