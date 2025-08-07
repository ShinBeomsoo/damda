//
//  StreakManagerObservable.swift
//  damda
//
//  Created by SHIN BEOMSOO on 8/7/25.
//

import Foundation
import CoreData

class StreakManagerObservable: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var maxStreak: Int = 0

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        calculateStreaks()
    }

    func markToday(success: Bool) {
        let today = Calendar.current.startOfDay(for: Date())
        let fetch: NSFetchRequest<StreakRecord> = StreakRecord.fetchRequest()
        fetch.predicate = NSPredicate(format: "date == %@", today as NSDate)
        let record = (try? context.fetch(fetch))?.first ?? StreakRecord(context: context)
        record.date = today
        record.isSuccess = success
        try? context.save()
        calculateStreaks()
    }

    func calculateStreaks() {
        let fetch: NSFetchRequest<StreakRecord> = StreakRecord.fetchRequest()
        fetch.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        guard let records = try? context.fetch(fetch) else { return }
        var streak = 0
        var maxStreak = 0
        var prevDate: Date? = nil

        for record in records where record.isSuccess {
            if let prev = prevDate,
               Calendar.current.date(byAdding: .day, value: 1, to: prev) == record.date {
                streak += 1
            } else {
                streak = 1
            }
            if streak > maxStreak { maxStreak = streak }
            prevDate = record.date
        }
        self.currentStreak = streak
        self.maxStreak = maxStreak
    }
}
