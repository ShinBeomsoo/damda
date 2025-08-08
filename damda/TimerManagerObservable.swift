import Foundation
import CoreData
import Combine

class TimerManagerObservable: ObservableObject {
    @Published var currentSession: TimerSession?
    @Published var elapsedSeconds: [TimerSession: Int] = [
        .morning: 0, .afternoon: 0, .evening: 0
    ]

    private let context: NSManagedObjectContext
    private let manager: TimerManager
    private var timer: Timer?
    private var autoSaveTimer: Timer?

    init(context: NSManagedObjectContext) {
        self.context = context
        self.manager = TimerManager(context: context)
        self.currentSession = manager.currentSession
        self.elapsedSeconds = manager.elapsedSeconds
        
        // 앱 재시작 시 세션 복원
        restoreSessionIfNeeded()
        
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
        startTimerTick()
        saveCurrentSession()
    }

    func pause() {
        manager.pause()
        syncFromManager()
        stopTimerTick()
        saveCurrentSession()
    }

    func reset() {
        manager.reset()
        syncFromManager()
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
        if let savedSessionRaw = UserDefaults.standard.object(forKey: "currentSession") as? String,
           let savedSession = TimerSession(rawValue: savedSessionRaw) {
            currentSession = savedSession
        }
        
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
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedSeconds[session, default: 0] += 1
        }
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