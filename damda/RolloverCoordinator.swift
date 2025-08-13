import Foundation
import CoreData

enum RolloverCoordinator {
    /// 자정 롤오버: 어제 기록 저장 후 오늘 상태 초기화 및 streak 반영
    static func endOfDay(
        now: Date = Date(),
        timerManager: TimerManagerObservable,
        todoManager: TodoManagerObservable,
        streakManager: StreakManagerObservable,
        goalSeconds: Int = 6 * 3600,
        goalTodos: Int = 5,
        context: NSManagedObjectContext? = nil
    ) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return }

        // 1) 어제 타이머 기록 저장
        saveTimerRecord(for: yesterday, timerManager: timerManager, context: context)

        // 2) 어제 목표 충족 여부 계산 후 streak 반영
        let yesterdaySeconds = totalSecondsStored(for: yesterday, context: effectiveContext(context))
        let yesterdayTodos = completedTodosCount(on: yesterday, todoManager: todoManager)
        let success = (yesterdaySeconds >= goalSeconds) && (yesterdayTodos >= goalTodos)
        // streakManager는 내부적으로 최신 기록을 재계산하므로, 어제 기록을 저장하려면 직접 엔티티 삽입 대신 API 사용
        streakManager.markToday(success: success)

        // 3) 오늘 상태 초기화
        timerManager.reset()
    }

    private static func saveTimerRecord(for day: Date, timerManager: TimerManagerObservable, context: NSManagedObjectContext?) {
        // TimerManager는 오늘 날짜에 저장하도록 설계되어 있어, 직접 CoreData에 저장한다.
        let context = effectiveContext(context)
        let fetch: NSFetchRequest<TimerRecord> = TimerRecord.fetchRequest()
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: day)
        fetch.predicate = NSPredicate(format: "date == %@", dayStart as NSDate)
        let record = (try? context.fetch(fetch))?.first ?? TimerRecord(context: context)
        record.date = dayStart
        record.morning = Int64(timerManager.elapsedSeconds[.morning] ?? 0)
        record.afternoon = Int64(timerManager.elapsedSeconds[.afternoon] ?? 0)
        record.evening = Int64(timerManager.elapsedSeconds[.evening] ?? 0)
        try? context.save()
    }

    private static func effectiveContext(_ ctx: NSManagedObjectContext?) -> NSManagedObjectContext {
        ctx ?? PersistenceController.shared.container.viewContext
    }

    private static func totalSecondsStored(for day: Date, context: NSManagedObjectContext) -> Int {
        let fetch: NSFetchRequest<TimerRecord> = TimerRecord.fetchRequest()
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        fetch.predicate = NSPredicate(format: "date == %@", start as NSDate)
        let record = (try? context.fetch(fetch))?.first
        return Int((record?.morning ?? 0) + (record?.afternoon ?? 0) + (record?.evening ?? 0))
    }

    private static func completedTodosCount(on day: Date, todoManager: TodoManagerObservable) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let byDay = todoManager.completedCountByDateRange(start: start, end: end)
        return byDay[start] ?? 0
    }
}


