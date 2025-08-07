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
    @State private var editingTodoID: NSManagedObjectID? = nil
    @State private var editingText: String = ""

    let rowHeight: CGFloat = 50
    let visibleRows: CGFloat = 5

    var sortedTodos: [Todo] {
        todoManager.todos.sorted { $0.priority > $1.priority }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 입력창: 항상 고정
            HStack {
                TextField("오늘의 할 일을 입력하세요", text: $newTodoText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Picker("우선순위", selection: $newTodoPriority) {
                    ForEach(1...10, id: \.self) { value in
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

            // 리스트만 스크롤, 5개 row 높이 고정
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(sortedTodos, id: \.objectID) { todo in
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "flag.fill")
                                    .foregroundColor(priorityColor(Int(todo.priority)))
                                Text("\(todo.priority)")
                                    .font(.system(size: 11))
                                    .foregroundColor(priorityColor(Int(todo.priority)))
                                Button(action: {
                                    todoManager.toggleComplete(todo: todo)
                                }) {
                                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(todo.isCompleted ? .blue : .red)
                                }
                                .buttonStyle(.plain)
                                if editingTodoID == todo.objectID {
                                    TextField("수정", text: $editingText, onCommit: {
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
                                    .frame(maxWidth: 200)
                                } else {
                                    Text(todo.text ?? "")
                                        .foregroundColor(todo.isCompleted ? .blue : .red)
                                        .onTapGesture(count: 2) {
                                            editingTodoID = todo.objectID
                                            editingText = todo.text ?? ""
                                        }
                                }
                                Spacer()
                                Button(action: {
                                    todoManager.deleteTodo(todo: todo)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(height: rowHeight)
                            Divider()
                        }
                    }
                }
            }
            .frame(height: rowHeight * visibleRows)
        }
        .padding()
    }

    func priorityColor(_ value: Int) -> Color {
        switch value {
        case 8...10: return .red
        case 5...7: return .orange
        case 3...4: return .yellow
        default: return .gray
        }
    }
}
