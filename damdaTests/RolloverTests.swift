import XCTest
import CoreData
@testable import damda

final class RolloverTests: XCTestCase {
    private func makeInMemoryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "damda")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
        return container
    }

    private func makeYMD(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        return Calendar.current.date(from: comps) ?? Date()
    }

    func testTimerRolloverSavesAndResets() throws {
        // Given: 2025-01-02 00:00 시점에 롤오버(어제 1일 분 저장)
        let container = makeInMemoryContainer()
        let context = container.viewContext
        let timerManager = TimerManagerObservable(context: context)

        // 어제에 해당하는 누적(테스트에서는 롤오버 직전 누적값)을 3600초로 가정
        timerManager.elapsedSeconds[.morning] = 1200
        timerManager.elapsedSeconds[.afternoon] = 1200
        timerManager.elapsedSeconds[.evening] = 1200

        let now = makeYMD(2025, 1, 2, hour: 0) // 자정 시점

        // When: 롤오버 수행
        RolloverCoordinator.endOfDay(
            now: now,
            timerManager: timerManager,
            todoManager: TodoManagerObservable(context: context),
            streakManager: StreakManagerObservable(context: context),
            context: context
        )

        // Then: 어제 날짜(1일)에 TimerRecord 저장, 오늘 누적은 0으로 초기화
        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: now))!

        let fetch: NSFetchRequest<TimerRecord> = TimerRecord.fetchRequest()
        fetch.predicate = NSPredicate(format: "date == %@", cal.startOfDay(for: yesterday) as NSDate)
        let records = try context.fetch(fetch)
        XCTAssertEqual(records.count, 1)
        let r = try XCTUnwrap(records.first)
        XCTAssertEqual(Int(r.morning) + Int(r.afternoon) + Int(r.evening), 3600)

        XCTAssertEqual(timerManager.elapsedSeconds[.morning], 0)
        XCTAssertEqual(timerManager.elapsedSeconds[.afternoon], 0)
        XCTAssertEqual(timerManager.elapsedSeconds[.evening], 0)
    }

    func testTodoTodayCountResetsAfterRollover() throws {
        // Given
        let container = makeInMemoryContainer()
        let context = container.viewContext
        let todoManager = TodoManagerObservable(context: context)
        let timerManager = TimerManagerObservable(context: context)
        let streakManager = StreakManagerObservable(context: context)

        let now = makeYMD(2025, 1, 2, hour: 0)
        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: now))!

        // 어제 완료된 할 일 2개
        let todos: [Todo] = (0..<2).map { _ in Todo(context: context) }
        for t in todos {
            t.id = Int64(Date().timeIntervalSince1970 * 1000)
            t.text = "done"
            t.createdAt = yesterday
            t.isCompleted = true
            t.completedAt = yesterday
            t.priority = 5
        }
        try context.save()

        // When: 롤오버 수행
        RolloverCoordinator.endOfDay(
            now: now,
            timerManager: timerManager,
            todoManager: todoManager,
            streakManager: streakManager,
            context: context
        )

        // Then: 오늘(2일) 완료 수는 0으로 계산되어야 함
        let today = cal.startOfDay(for: now)
        let start = today
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let byDay = todoManager.completedCountByDateRange(start: start, end: end)
        XCTAssertEqual(byDay[today] ?? 0, 0)
    }

    func testStreakUpdatedOnGoalMetDuringRollover() throws {
        // Given: 6시간 학습 + 5개 완료 → 성공
        let container = makeInMemoryContainer()
        let context = container.viewContext
        let todoManager = TodoManagerObservable(context: context)
        let timerManager = TimerManagerObservable(context: context)
        let streakManager = StreakManagerObservable(context: context)

        let now = makeYMD(2025, 1, 2, hour: 0)
        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: now))!

        // 롤오버 직전 누적 6시간
        timerManager.elapsedSeconds[.morning] = 2 * 3600
        timerManager.elapsedSeconds[.afternoon] = 2 * 3600
        timerManager.elapsedSeconds[.evening] = 2 * 3600

        // 어제 완료된 할 일 5개
        for _ in 0..<5 {
            let t = Todo(context: context)
            t.id = Int64(Date().timeIntervalSince1970 * 1000)
            t.text = "done"
            t.createdAt = yesterday
            t.isCompleted = true
            t.completedAt = yesterday
            t.priority = 5
        }
        try context.save()

        // When
        RolloverCoordinator.endOfDay(
            now: now,
            timerManager: timerManager,
            todoManager: todoManager,
            streakManager: streakManager,
            goalSeconds: 6 * 3600,
            goalTodos: 5,
            context: context
        )

        // Then: 어제 날짜로 streak 성공 기록이 남아 current/maxStreak가 1 이상
        XCTAssertGreaterThanOrEqual(streakManager.currentStreak, 1)
        XCTAssertGreaterThanOrEqual(streakManager.maxStreak, 1)
    }
}


