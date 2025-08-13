//
//  TimeManagerTests.swift
//  damdaTests
//
//  Created by SHIN BEOMSOO on 8/7/25.
//

import XCTest
import CoreData
@testable import damda

class TimerManagerTests: XCTestCase {
    var persistentContainer: NSPersistentContainer!
    var timerManager: TimerManager!

    override func setUp() {
        super.setUp()
        persistentContainer = NSPersistentContainer(name: "damda")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        persistentContainer.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
        timerManager = TimerManager(context: persistentContainer.viewContext)
    }

    override func tearDown() {
        timerManager = nil
        persistentContainer = nil
        super.tearDown()
    }

    func testStartAndPauseSession() {
        timerManager.start(session: .morning)
        XCTAssertEqual(timerManager.currentSession, .morning)
        // 타이머를 2초간 실행한 것처럼 시뮬레이션 (pause 시 추가 가산 없음 정책)
        timerManager.elapsedSeconds[.morning] = 2
        timerManager.pause()
        XCTAssertNil(timerManager.currentSession)
        XCTAssertEqual(timerManager.elapsedSeconds[.morning], 2)
    }

    func testResetAllSessions() {
        timerManager.elapsedSeconds[.morning] = 10
        timerManager.elapsedSeconds[.afternoon] = 20
        timerManager.elapsedSeconds[.evening] = 30
        timerManager.reset()
        XCTAssertEqual(timerManager.elapsedSeconds[.morning], 0)
        XCTAssertEqual(timerManager.elapsedSeconds[.afternoon], 0)
        XCTAssertEqual(timerManager.elapsedSeconds[.evening], 0)
    }

    func testOnlyOneSessionActive() {
        timerManager.start(session: .morning)
        XCTAssertEqual(timerManager.currentSession, .morning)
        timerManager.start(session: .afternoon)
        XCTAssertEqual(timerManager.currentSession, .afternoon)
        // 이전 세션은 자동으로 중지되어야 함
    }

    func testSaveAndLoadTodayRecord() {
        timerManager.elapsedSeconds[.morning] = 100
        timerManager.elapsedSeconds[.afternoon] = 200
        timerManager.elapsedSeconds[.evening] = 300
        timerManager.saveTodayRecord()

        // 새로운 매니저로 불러오기
        let newManager = TimerManager(context: persistentContainer.viewContext)
        XCTAssertEqual(newManager.elapsedSeconds[.morning], 100)
        XCTAssertEqual(newManager.elapsedSeconds[.afternoon], 200)
        XCTAssertEqual(newManager.elapsedSeconds[.evening], 300)
    }
}
