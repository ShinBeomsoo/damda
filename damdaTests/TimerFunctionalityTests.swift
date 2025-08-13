//
//  TimerFunctionalityTests.swift
//  damdaTests
//
//  Created by SHIN BEOMSOO on 8/8/25.
//

import XCTest
import CoreData
@testable import damda

final class TimerFunctionalityTests: XCTestCase {
    
    func testTimerStart() async throws {
        // Core Data 컨텍스트 생성
        let context = PersistenceController.shared.container.viewContext
        
        // TimerManagerObservable 생성
        let timerManager = TimerManagerObservable(context: context)
        
        // 초기 상태 확인
        XCTAssertNil(timerManager.currentSession)
        XCTAssertEqual(timerManager.elapsedSeconds[.morning], 0)
        
        // 타이머 시작
        timerManager.start(session: .morning)
        
        // 시작 후 상태 확인
        XCTAssertEqual(timerManager.currentSession, .morning)
        
        // 잠시 대기 후 시간 증가 확인
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2초 대기
        
        XCTAssertGreaterThan(timerManager.elapsedSeconds[.morning] ?? 0, 0)
        
        // 타이머 정지
        timerManager.pause()
        XCTAssertNil(timerManager.currentSession)
    }
    
    func testTimerPause() async throws {
        let context = PersistenceController.shared.container.viewContext
        let timerManager = TimerManagerObservable(context: context)
        
        // 타이머 시작
        timerManager.start(session: .afternoon)
        XCTAssertEqual(timerManager.currentSession, .afternoon)
        
        // 잠시 대기
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5초 대기 (정수 절단 방지)
        
        let beforePause = timerManager.elapsedSeconds[.afternoon] ?? 0
        
        // 타이머 정지
        timerManager.pause()
        XCTAssertNil(timerManager.currentSession)
        
        // 정지 후 시간이 증가하지 않았는지 확인
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5초 더 대기
        let afterPause = timerManager.elapsedSeconds[.afternoon] ?? 0
        XCTAssertEqual(afterPause, beforePause)
    }
    
    func testTimerReset() async throws {
        let context = PersistenceController.shared.container.viewContext
        let timerManager = TimerManagerObservable(context: context)
        
        // 타이머 시작하고 시간 증가
        timerManager.start(session: .evening)
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5초 대기
        
        // 리셋 전에 시간이 증가했는지 확인
        XCTAssertGreaterThan(timerManager.elapsedSeconds[.evening] ?? 0, 0)
        
        // 리셋
        timerManager.reset()
        
        // 모든 세션이 0으로 리셋되었는지 확인
        XCTAssertEqual(timerManager.elapsedSeconds[.morning], 0)
        XCTAssertEqual(timerManager.elapsedSeconds[.afternoon], 0)
        XCTAssertEqual(timerManager.elapsedSeconds[.evening], 0)
        XCTAssertNil(timerManager.currentSession)
    }
    
    func testMultipleSessions() async throws {
        let context = PersistenceController.shared.container.viewContext
        let timerManager = TimerManagerObservable(context: context)
        
        // 아침 세션 시작
        timerManager.start(session: .morning)
        try await Task.sleep(nanoseconds: 1_200_000_000) // 1.2초 대기
        
        // 오후 세션으로 변경 (아침 세션이 자동으로 정지되어야 함)
        timerManager.start(session: .afternoon)
        XCTAssertEqual(timerManager.currentSession, .afternoon)
        
        // 아침 세션 시간이 저장되었는지 확인
        XCTAssertGreaterThan(timerManager.elapsedSeconds[.morning] ?? 0, 0)
        
        // 저녁 세션으로 변경
        timerManager.start(session: .evening)
        XCTAssertEqual(timerManager.currentSession, .evening)
        
        // 오후 세션 시간이 저장되었는지 확인
        XCTAssertGreaterThan(timerManager.elapsedSeconds[.afternoon] ?? 0, 0)
    }
} 