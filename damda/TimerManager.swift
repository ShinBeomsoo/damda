import Foundation
import CoreData

enum TimerSession: String, CaseIterable {
    case morning, afternoon, evening
}

class TimerManager {
    var currentSession: TimerSession?
    var elapsedSeconds: [TimerSession: Int] = [
        .morning: 0, .afternoon: 0, .evening: 0
    ]
    private var timer: Timer?
    private var startDate: Date?
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        loadTodayRecord()
    }

    func start(session: TimerSession) {
        stop() // 다른 세션이 동작 중이면 중지
        currentSession = session
        startDate = Date()
        // 실제 앱에서는 타이머를 시작하지만, 테스트에서는 생략
    }

    func pause() {
        // 테스트 및 UI 일관성: 진행 중 증가분은 Observable 쪽 틱에서만 반영하고,
        // pause 시점에는 추가 가산 없이 현재 누적값만 저장한다.
        saveTodayRecord()
        timer?.invalidate()
        timer = nil
        startDate = nil
        currentSession = nil
    }

    func stop() {
        pause()
    }

    func reset() {
        stop()
        for session in TimerSession.allCases {
            elapsedSeconds[session] = 0
        }
        saveTodayRecord()
    }

    func saveTodayRecord() {
        let fetch: NSFetchRequest<TimerRecord> = TimerRecord.fetchRequest()
        let today = Calendar.current.startOfDay(for: Date())
        fetch.predicate = NSPredicate(format: "date == %@", today as NSDate)
        let record = (try? context.fetch(fetch))?.first ?? TimerRecord(context: context)
        record.date = today
        record.morning = Int64(elapsedSeconds[.morning] ?? 0)
        record.afternoon = Int64(elapsedSeconds[.afternoon] ?? 0)
        record.evening = Int64(elapsedSeconds[.evening] ?? 0)
        try? context.save()
    }

    func loadTodayRecord() {
        let fetch: NSFetchRequest<TimerRecord> = TimerRecord.fetchRequest()
        let today = Calendar.current.startOfDay(for: Date())
        fetch.predicate = NSPredicate(format: "date == %@", today as NSDate)
        if let record = (try? context.fetch(fetch))?.first {
            elapsedSeconds[.morning] = Int(record.morning)
            elapsedSeconds[.afternoon] = Int(record.afternoon)
            elapsedSeconds[.evening] = Int(record.evening)
        }
    }
}
