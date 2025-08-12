import Foundation
import CoreData
import Combine

class TimerManagerObservable: ObservableObject {
    @Published var currentSession: TimerSession?
    @Published var elapsedSeconds: [TimerSession: Int] = [
        .morning: 0, .afternoon: 0, .evening: 0
    ]
    @Published var isRunning: Bool = false

    private let context: NSManagedObjectContext
    private let manager: TimerManager
    private var timer: Timer?
    private var autoSaveTimer: Timer?

    init(context: NSManagedObjectContext) {
        self.context = context
        self.manager = TimerManager(context: context)
        self.currentSession = manager.currentSession
        self.elapsedSeconds = manager.elapsedSeconds
        
        // 앱 재시작 시, 현재 진행 중 세션은 복원하지 않고(초기에는 모두 '시작' 상태), 누적 시간만 복원
        restoreSessionIfNeeded()
        self.currentSession = nil
        self.isRunning = false
        
        // 자동 저장 타이머 시작
        startAutoSaveTimer()
    }
    
    deinit {
        stopAutoSaveTimer()
        stopTimerTick()
    }

    // MARK: - Controls
    func start(session: TimerSession) {
        manager.start(session: session)
        syncFromManager()
        isRunning = true
        startTimerTick()
        saveCurrentSession()
    }

    func pause() {
        manager.pause()
        syncFromManager()
        isRunning = false
        stopTimerTick()
        saveCurrentSession()
    }

    func reset() {
        manager.reset()
        syncFromManager()
        isRunning = false
        stopTimerTick()
        clearSavedSession()
    }

    // MARK: - Session Persistence
    private func saveCurrentSession() {
        UserDefaults.standard.set(currentSession?.rawValue, forKey: "currentSession")
        
        // elapsedSeconds를 String 키로 변환하여 저장
        var savedElapsedSeconds: [String: Int] = [:]
        for (session, seconds) in elapsedSeconds {
            savedElapsedSeconds[session.rawValue] = seconds
        }
        UserDefaults.standard.set(savedElapsedSeconds, forKey: "elapsedSeconds")
    }
    
    private func restoreSessionIfNeeded() {
        // 현재 진행 세션은 복원하지 않음 (초기엔 모두 '시작' 상태를 원함)
        if let savedElapsedSeconds = UserDefaults.standard.object(forKey: "elapsedSeconds") as? [String: Int] {
            var restoredSeconds: [TimerSession: Int] = [:]
            for (key, value) in savedElapsedSeconds {
                if let session = TimerSession(rawValue: key) {
                    restoredSeconds[session] = value
                }
            }
            elapsedSeconds = restoredSeconds
        }
    }
    
    private func clearSavedSession() {
        UserDefaults.standard.removeObject(forKey: "currentSession")
        UserDefaults.standard.removeObject(forKey: "elapsedSeconds")
    }

    // MARK: - Sync & Tick
    private func syncFromManager() {
        self.currentSession = manager.currentSession
        self.elapsedSeconds = manager.elapsedSeconds
    }

    private func startTimerTick() {
        stopTimerTick()
        guard let session = currentSession else { return }
        let newTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // 명시적으로 변경 이벤트와 재할당로 퍼블리시 강제
                self.objectWillChange.send()
                var next = self.elapsedSeconds
                next[session, default: 0] += 1
                self.elapsedSeconds = next
            }
        }
        self.timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }

    private func stopTimerTick() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Auto Save
    private func startAutoSaveTimer() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.saveCurrentSession()
        }
    }
    
    private func stopAutoSaveTimer() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }

    // MARK: - Aggregations
    var totalSeconds: Int {
        elapsedSeconds.values.reduce(0, +)
    }

    func dailyTimeRecords(forDays days: Int) -> [(date: Date, seconds: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [(Date, Int)] = []
        for i in (0..<days).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let fetch: NSFetchRequest<TimerRecord> = TimerRecord.fetchRequest()
            fetch.predicate = NSPredicate(format: "date == %@", date as NSDate)
            let records = try? self.context.fetch(fetch)
            let record = records?.first
            let seconds: Int
            if let r = record {
                seconds = Int(r.morning) + Int(r.afternoon) + Int(r.evening)
            } else {
                seconds = 0
            }
            result.append((date, seconds))
        }
        return result
    }

    // 새로 추가: 주어진 기간의 일자별 총 초 집계
    func dailySecondsByDateRange(start: Date, end: Date) -> [Date: Int] {
        let fetch: NSFetchRequest<TimerRecord> = TimerRecord.fetchRequest()
        fetch.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        guard let records = try? context.fetch(fetch) else { return [:] }
        let calendar = Calendar.current
        var result: [Date: Int] = [:]
        for r in records {
            let date = r.date ?? Date()
            let day = calendar.startOfDay(for: date)
            let seconds = Int(r.morning) + Int(r.afternoon) + Int(r.evening)
            result[day, default: 0] += seconds
        }
        return result
    }
}