//
//  TodoListView.swift
//  damda
//
//  Created by SHIN BEOMSOO on 8/7/25.
//

import SwiftUI

struct TodoListView: View {
    @ObservedObject var todoManager: TodoManagerObservable
    @State private var newTodoText: String = ""
    @State private var newTodoPriority: Int = 5
    @State private var editingTodoID: NSManagedObjectID?
    @State private var editingText: String = ""
    @State private var editingPriority: Int = 5
    @State private var renderTrigger = false

    var sortedTodos: [Todo] {
        let todos: [Todo] = todoManager.todos
        let sorted: [Todo] = todos.sorted { (a: Todo, b: Todo) -> Bool in
            a.priority > b.priority
        }
        return sorted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("오늘의 할 일")
                .font(.headline)
            HStack {
                TextField("오늘의 할 일을 입력하세요", text: $newTodoText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Picker("우선순위", selection: $newTodoPriority) {
                    ForEach(1...10, id: \ .self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .frame(width: 60)
                Button("추가") {
                    guard !newTodoText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    todoManager.addTodo(text: newTodoText, priority: Int16(newTodoPriority))
                    newTodoText = ""
                    newTodoPriority = 5
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 8)

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
                    .font(.system(size: 11))
                    .foregroundColor(priorityColor(Int(todo.priority)))

                if editingTodoID == todo.objectID {
                    TextField("할 일 수정", text: $editingText, onCommit: {
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
