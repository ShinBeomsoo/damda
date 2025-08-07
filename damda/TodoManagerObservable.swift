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
        print("isCompleted:", todo.isCompleted)
        if todo.isCompleted {
            todo.completedAt = Date()
        } else {
            todo.completedAt = nil
        }
        try? context.save()
        fetchTodos()
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

    var completedCount: Int {
        todos.filter { $0.isCompleted }.count
    }
}
