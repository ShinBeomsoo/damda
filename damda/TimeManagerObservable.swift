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

    private let manager: TimerManager
    private var timer: Timer?

    init(context: NSManagedObjectContext) {
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
}
