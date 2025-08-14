//
//  TodoListView.swift
//  damda
//
//  Created by SHIN BEOMSOO on 8/7/25.
//

import SwiftUI

struct TodoListView: View {
    @ObservedObject var todoManager: TodoManagerObservable
    @State private var editingTodoID: NSManagedObjectID?
    @State private var editingText: String = ""
    @State private var editingPriority: Int = 5
    @State private var renderTrigger = false

    var sortedTodos: [Todo] {
        // 오늘 기준 표시 정책:
        // - 미완료
        // - 혹은 '오늘 완료된' 항목만 포함
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let todayEnd = cal.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart

        let todos: [Todo] = todoManager.todos.filter { t in
            if t.isCompleted == false { return true }
            if let done = t.completedAt { return (done >= todayStart && done < todayEnd) }
            return false
        }
        let sorted: [Todo] = todos.sorted { (a: Todo, b: Todo) -> Bool in
            a.priority > b.priority
        }
        return sorted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localized("오늘의 할 일"))
                .font(.pretendard(18, weight: .semibold))

            ScrollView {
                let todos: [Todo] = sortedTodos
                LazyVStack(spacing: 0) {
                    ForEach(todos, id: \ .objectID) { todo in
                        TodoRowView(
                            todo: todo,
                            editingTodoID: $editingTodoID,
                            editingText: $editingText,
                            editingPriority: $editingPriority,
                            todoManager: todoManager,
                            renderTrigger: $renderTrigger
                        )
                    }
                }
                .id(renderTrigger)
            }
            .frame(height: 50 * 5)
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
    }
    func priorityColor(_ value: Int) -> Color {
        switch value {
        case 8...10: return .red
        case 5...7: return .orange
        default: return .gray
        }
    }
}

struct TodoRowView: View {
    let todo: Todo
    @Binding var editingTodoID: NSManagedObjectID?
    @Binding var editingText: String
    @Binding var editingPriority: Int
    var todoManager: TodoManagerObservable
    @Binding var renderTrigger: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    todoManager.toggleComplete(todo: todo)
                    renderTrigger.toggle()
                }) {
                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(todo.isCompleted ? .blue : .red)
                }
                .buttonStyle(.plain)

                Image(systemName: "flag.fill")
                    .foregroundColor(priorityColor(Int(todo.priority)))
                Text("\(todo.priority)")
                    .font(.pretendard(11))
                    .foregroundColor(priorityColor(Int(todo.priority)))

                if editingTodoID == todo.objectID {
                    TextField(LocalizationManager.shared.localized("할 일 수정"), text: $editingText, onCommit: {
                        todoManager.updateTodoText(todo: todo, newText: editingText)
                        editingTodoID = nil
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onDisappear {
                        if editingTodoID == todo.objectID {
                            todoManager.updateTodoText(todo: todo, newText: editingText)
                            editingTodoID = nil
                        }
                    }
                } else {
                    Text(todo.text ?? "")
                        .foregroundColor(todo.isCompleted ? .blue : .red)
                        .strikethrough(todo.isCompleted, color: .blue)
                        .onTapGesture(count: 2) {
                            editingTodoID = todo.objectID
                            editingText = todo.text ?? ""
                            editingPriority = Int(todo.priority)
                        }
                }
                Spacer()
                Button(action: {
                    todoManager.deleteTodo(todo: todo)
                    renderTrigger.toggle()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
            Divider()
        }
    }
    func priorityColor(_ value: Int) -> Color {
        switch value {
        case 8...10: return .red
        case 5...7: return .orange
        default: return .gray
        }
    }
}
