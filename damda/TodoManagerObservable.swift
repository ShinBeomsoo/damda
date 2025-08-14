//
//  TodoManagerObservable.swift
//  damda
//
//  Created by SHIN BEOMSOO on 8/7/25.
//

import Foundation
import CoreData
import Combine

class TodoManagerObservable: ObservableObject {
    @Published var todos: [Todo] = []
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchTodos()
    }

    func fetchTodos() {
        let fetchRequest: NSFetchRequest<Todo> = Todo.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        if let results = try? context.fetch(fetchRequest) {
            todos = results.map { $0 }
        }
    }

    func addTodo(text: String, priority: Int16 = 5) {
        let todo = Todo(context: context)
        todo.id = Int64(Date().timeIntervalSince1970 * 1000)
        todo.text = text
        todo.createdAt = Date()
        todo.isCompleted = false
        todo.priority = priority
        try? context.save()
        fetchTodos()
    }

    func toggleComplete(todo: Todo) {
        todo.isCompleted.toggle()
        if todo.isCompleted {
            todo.completedAt = Date()
        } else {
            todo.completedAt = nil
        }
        try? context.save()
        fetchTodos()
    }

    /// 자정 롤오버 시, 모든 할 일의 완료 상태를 초기화한다.
    func resetAllTodosCompletionStatus() {
        let fetch: NSFetchRequest<Todo> = Todo.fetchRequest()
        if let items = try? context.fetch(fetch) {
            for t in items {
                t.isCompleted = false
                t.completedAt = nil
            }
            try? context.save()
            fetchTodos()
        }
    }

    // MARK: - Snapshot (JSON-based)
    func saveSnapshotForDay(_ day: Date) {
        let completed = completedTodos(on: day).map { $0.text ?? "" }
        let uncompleted = uncompletedTodos(on: day).map { $0.text ?? "" }
        TodoSnapshotStore.shared.save(day: day, completed: completed, uncompleted: uncompleted)
    }
    func loadSnapshotForDay(_ day: Date) -> TodoDaySnapshot? {
        TodoSnapshotStore.shared.load(day: day)
    }

    func deleteTodo(todo: Todo) {
        context.delete(todo)
        try? context.save()
        fetchTodos()
    }

    func updateTodoText(todo: Todo, newText: String) {
        todo.text = newText
        try? context.save()
        fetchTodos()
    }

    func dailyCompletedTodos(forDays days: Int) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [(Date, Int)] = []
        for i in (0..<days).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let count = todos.filter {
                $0.isCompleted && Calendar.current.isDate($0.completedAt ?? Date.distantPast, inSameDayAs: date)
            }.count
            result.append((date, count))
        }
        return result
    }

    func completedCountByDateRange(start: Date, end: Date) -> [Date: Int] {
        let fetch: NSFetchRequest<Todo> = Todo.fetchRequest()
        fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isCompleted == YES"),
            NSPredicate(format: "completedAt >= %@ AND completedAt < %@", start as NSDate, end as NSDate)
        ])
        guard let items = try? context.fetch(fetch) else { return [:] }
        let calendar = Calendar.current
        var result: [Date: Int] = [:]
        for t in items {
            if let completedAt = t.completedAt {
                let day = calendar.startOfDay(for: completedAt)
                result[day, default: 0] += 1
            }
        }
        return result
    }

    var completedCount: Int {
        todos.filter { $0.isCompleted }.count
    }

    /// 오늘 완료된 할 일 개수 (오늘 목표 판단/표시에 사용)
    var todayCompletedCount: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return todos.filter { t in
            guard t.isCompleted, let done = t.completedAt else { return false }
            return done >= start && done < end
        }.count
    }

    /// 선택한 날짜 기준으로 (해당 날짜까지 존재하던) 할 일의 완료/미완료 개수를 반환한다.
    /// - completed: completedAt이 그 날짜에 속한 항목 수
    /// - uncompleted: 해당 날짜 끝 시점까지 존재(createdAt <= end)한 전체 수 - completed
    func completedAndUncompletedCounts(on day: Date) -> (completed: Int, uncompleted: Int) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start

        // 해당 날짜까지 존재하던 모든 할 일
        let allFetch: NSFetchRequest<Todo> = Todo.fetchRequest()
        allFetch.predicate = NSPredicate(format: "createdAt <= %@", end as NSDate)
        let allCount: Int = (try? context.count(for: allFetch)) ?? 0

        // 해당 날짜에 완료된 할 일
        let doneFetch: NSFetchRequest<Todo> = Todo.fetchRequest()
        doneFetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isCompleted == YES"),
            NSPredicate(format: "completedAt >= %@ AND completedAt < %@", start as NSDate, end as NSDate)
        ])
        let completed: Int = (try? context.count(for: doneFetch)) ?? 0
        let uncompleted = max(0, allCount - completed)
        return (completed, uncompleted)
    }

    /// 선택한 날짜에 완료된 할 일 목록(완료 시각이 그 날짜에 속한 항목)
    func completedTodos(on day: Date) -> [Todo] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let fetch: NSFetchRequest<Todo> = Todo.fetchRequest()
        fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isCompleted == YES"),
            NSPredicate(format: "completedAt >= %@ AND completedAt < %@", start as NSDate, end as NSDate)
        ])
        fetch.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: true)]
        return (try? context.fetch(fetch)) ?? []
    }

    /// 선택한 날짜 기준 미완료로 간주되는 할 일 목록
    /// (해당 날짜 종료 시점까지 존재했으나, 그 날짜 안에는 완료되지 않은 항목)
    func uncompletedTodos(on day: Date) -> [Todo] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let fetch: NSFetchRequest<Todo> = Todo.fetchRequest()
        fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "createdAt <= %@", end as NSDate),
            NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "isCompleted == NO"),
                NSPredicate(format: "completedAt >= %@", end as NSDate)
            ])
        ])
        fetch.sortDescriptors = [
            NSSortDescriptor(key: "priority", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]
        return (try? context.fetch(fetch)) ?? []
    }
}
