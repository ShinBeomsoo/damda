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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                TextField("오늘의 할 일을 입력하세요", text: $newTodoText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("추가") {
                    guard !newTodoText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    todoManager.addTodo(text: newTodoText)
                    newTodoText = ""
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 8)

            List {
                ForEach(todoManager.todos, id: \.objectID) { todo in
                    HStack {
                        Button(action: {
                            todoManager.toggleComplete(todo: todo)
                        }) {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(todo.isCompleted ? .blue : .red)
                        }
                        .buttonStyle(.plain)
                        Text(todo.text ?? "")
                            .foregroundColor(todo.isCompleted ? .blue : .red)
                        Spacer()
                        Button(action: {
                            todoManager.deleteTodo(todo: todo)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
        }
        .padding()
    }
}
