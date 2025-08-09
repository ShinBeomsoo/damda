import XCTest
@testable import damda

final class SM2SchedulerTests: XCTestCase {
    // 상태 모델과 스케줄러 API는 TDD로 다음 단계에서 구현됩니다.
    // 본 테스트는 SM-2 공식 규칙을 기준으로 기대값을 검증합니다.
    
    func testInitialSuccessWithGood() {
        // Given: 초기 상태 (EF=2.5, 반복 0, 간격 0일)
        let state = SM2State(easeFactor: 2.5, intervalDays: 0, repetitionCount: 0, lapseCount: 0)
        
        // When: 품질 q=5 (알고 있음)
        let next = SM2Scheduler.review(state: state, quality: 5)
        
        // Then: n=1, I=1일, EF=2.6 (하한 1.3 적용)
        XCTAssertEqual(next.repetitionCount, 1)
        XCTAssertEqual(next.intervalDays, 1)
        XCTAssertGreaterThanOrEqual(next.easeFactor, 1.3)
        XCTAssertEqual(round(next.easeFactor * 10) / 10, 2.6, accuracy: 0.0001)
    }
    
    func testSecondSuccessSetsSixDays() {
        // Given: 첫 성공 후 상태 (n=1, I=1, EF=2.6 가정)
        let state = SM2State(easeFactor: 2.6, intervalDays: 1, repetitionCount: 1, lapseCount: 0)
        
        // When: 품질 q=5 (알고 있음)
        let next = SM2Scheduler.review(state: state, quality: 5)
        
        // Then: n=2, I=6일 (SM-2 규칙), EF는 다시 +0.1 → 2.7 근사
        XCTAssertEqual(next.repetitionCount, 2)
        XCTAssertEqual(next.intervalDays, 6)
        XCTAssertEqual(round(next.easeFactor * 10) / 10, 2.7, accuracy: 0.0001)
    }
    
    func testSubsequentIntervalUsesMultiplication() {
        // Given: 두 번째 성공 후 상태 (n=2, I=6, EF=2.5)
        let state = SM2State(easeFactor: 2.5, intervalDays: 6, repetitionCount: 2, lapseCount: 0)
        
        // When: 품질 q=5 (알고 있음)
        let next = SM2Scheduler.review(state: state, quality: 5)
        
        // Then: n=3, I = round(6 * 2.6) ≈ 16 (EF는 +0.1 반영되어 2.6)
        XCTAssertEqual(next.repetitionCount, 3)
        XCTAssertEqual(next.intervalDays, Int(round(6 * 2.6)))
        XCTAssertEqual(round(next.easeFactor * 10) / 10, 2.6, accuracy: 0.0001)
    }
    
    func testFailResetsToLearning() {
        // Given: 진행 중 상태
        let state = SM2State(easeFactor: 2.5, intervalDays: 6, repetitionCount: 3, lapseCount: 0)
        
        // When: 품질 q=2 (모름)
        let next = SM2Scheduler.review(state: state, quality: 2)
        
        // Then: n=0, I=1일, lapseCount 증가, EF 하한 1.3 유지
        XCTAssertEqual(next.repetitionCount, 0)
        XCTAssertEqual(next.intervalDays, 1)
        XCTAssertEqual(next.lapseCount, state.lapseCount + 1)
        XCTAssertGreaterThanOrEqual(next.easeFactor, 1.3)
    }
    
    func testEaseFactorLowerBound() {
        // Given: EF를 지속적으로 깎는 입력(q=3)
        var state = SM2State(easeFactor: 1.35, intervalDays: 10, repetitionCount: 5, lapseCount: 0)
        
        // When: 여러 번 q=3 적용
        for _ in 0..<10 {
            state = SM2Scheduler.review(state: state, quality: 3)
        }
        
        // Then: EF는 1.3 미만으로 내려가지 않음
        XCTAssertGreaterThanOrEqual(state.easeFactor, 1.3)
    }
}