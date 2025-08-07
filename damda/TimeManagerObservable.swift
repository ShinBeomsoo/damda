//
//  TimeManagerObservable.swift
//  damda
//
//  Created by SHIN BEOMSOO on 8/7/25.
//

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

    init(context: NSManagedObjectContext) {
        self.context = context
        self.manager = TimerManager(context: context)
        self.currentSession = manager.currentSession
        self.elapsedSeconds = manager.elapsedSeconds
    }

    func start(session: TimerSession) {
        manager.start(session: session)
        syncFromManager()
        startTimerTick()
    }

    func pause() {
        manager.pause()
        syncFromManager()
        stopTimerTick()
    }

    func reset() {
        manager.reset()
        syncFromManager()
        stopTimerTick()
    }

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
}
