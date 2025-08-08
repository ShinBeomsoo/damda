//
//  TimerFunctionalityTests.swift
//  damdaTests
//
//  Created by SHIN BEOMSOO on 8/8/25.
//

import Testing
import CoreData
@testable import damda

struct TimerFunctionalityTests {
    
    @Test func testTimerStart() async throws {
        // Core Data 컨텍스트 생성
        let context = PersistenceController.shared.container.viewContext
        
        // TimerManagerObservable 생성
        let timerManager = TimerManagerObservable(context: context)
        
        // 초기 상태 확인
        #expect(timerManager.currentSession == nil)
        #expect(timerManager.elapsedSeconds[.morning] == 0)
        
        // 타이머 시작
        timerManager.start(session: .morning)
        
        // 시작 후 상태 확인
        #expect(timerManager.currentSession == .morning)
        
        // 잠시 대기 후 시간 증가 확인
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2초 대기
        
        #expect(timerManager.elapsedSeconds[.morning] ?? 0 > 0)
        
        // 타이머 정지
        timerManager.pause()
        #expect(timerManager.currentSession == nil)
    }
    
    @Test func testTimerPause() async throws {
        let context = PersistenceController.shared.container.viewContext
        let timerManager = TimerManagerObservable(context: context)
        
        // 타이머 시작
        timerManager.start(session: .afternoon)
        #expect(timerManager.currentSession == .afternoon)
        
        // 잠시 대기
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
        
        let beforePause = timerManager.elapsedSeconds[.afternoon] ?? 0
        
        // 타이머 정지
        timerManager.pause()
        #expect(timerManager.currentSession == nil)
        
        // 정지 후 시간이 증가하지 않았는지 확인
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1초 더 대기
        let afterPause = timerManager.elapsedSeconds[.afternoon] ?? 0
        #expect(afterPause == beforePause)
    }
    
    @Test func testTimerReset() async throws {
        let context = PersistenceController.shared.container.viewContext
        let timerManager = TimerManagerObservable(context: context)
        
        // 타이머 시작하고 시간 증가
        timerManager.start(session: .evening)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
        
        // 리셋 전에 시간이 증가했는지 확인
        #expect(timerManager.elapsedSeconds[.evening] ?? 0 > 0)
        
        // 리셋
        timerManager.reset()
        
        // 모든 세션이 0으로 리셋되었는지 확인
        #expect(timerManager.elapsedSeconds[.morning] == 0)
        #expect(timerManager.elapsedSeconds[.afternoon] == 0)
        #expect(timerManager.elapsedSeconds[.evening] == 0)
        #expect(timerManager.currentSession == nil)
    }
    
    @Test func testMultipleSessions() async throws {
        let context = PersistenceController.shared.container.viewContext
        let timerManager = TimerManagerObservable(context: context)
        
        // 아침 세션 시작
        timerManager.start(session: .morning)
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기
        
        // 오후 세션으로 변경 (아침 세션이 자동으로 정지되어야 함)
        timerManager.start(session: .afternoon)
        #expect(timerManager.currentSession == .afternoon)
        
        // 아침 세션 시간이 저장되었는지 확인
        #expect(timerManager.elapsedSeconds[.morning] ?? 0 > 0)
        
        // 저녁 세션으로 변경
        timerManager.start(session: .evening)
        #expect(timerManager.currentSession == .evening)
        
        // 오후 세션 시간이 저장되었는지 확인
        #expect(timerManager.elapsedSeconds[.afternoon] ?? 0 > 0)
    }
} 