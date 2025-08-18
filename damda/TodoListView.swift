//
//  TodoListView.swift
//  damda
//
//  Created by SHIN BEOMSOO on 8/7/25.
//

import SwiftUI
import Foundation

struct TodoListView: View {
    @ObservedObject var todoManager: TodoManagerObservable
    @State private var editingTodoID: NSManagedObjectID?
    @State private var editingText: String = ""
    @State private var editingPriority: Int = 5
    @State private var renderTrigger = false

    // Google Calendar 읽기 전용 섹션 상태
    @StateObject private var googleCalendarService = GoogleCalendarService()
    @State private var googleTodayEvents: [CalendarEvent] = []
    @State private var isLoadingGoogleEvents = false

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
            // 오늘의 Google 일정 (읽기 전용)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.green)
                    Text("오늘의 Google 일정")
                        .font(.pretendard(16, weight: .semibold))
                        .foregroundColor(.green)
                    Spacer()
                    if isLoadingGoogleEvents {
                        ProgressView().scaleEffect(0.7)
                    } else if googleCalendarService.isAuthenticated {
                        Button(action: { loadTodayGoogleEvents() }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.green)
                    } else {
                        Button(action: { Task { _ = try? await googleCalendarService.authenticate(); loadTodayGoogleEvents() } }) {
                            Text("연동")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if googleCalendarService.isAuthenticated {
                    if googleTodayEvents.isEmpty && !isLoadingGoogleEvents {
                        Text("오늘 일정이 없습니다")
                            .font(.pretendard(12))
                            .foregroundColor(.secondary)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(googleTodayEvents, id: \.id) { ev in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle().fill(Color.green).frame(width: 6, height: 6)
                                        .padding(.top, 6)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(ev.title)
                                            .font(.pretendard(13, weight: .medium))
                                            .foregroundColor(.primary)
                                        Text(googleEventTimeRange(ev.startDate, ev.endDate))
                                            .font(.pretendard(11))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.green.opacity(0.08))
            .cornerRadius(10)
            .onAppear {
                // 뷰 표시 시, 인증되어 있으면 오늘 일정 로드
                if googleCalendarService.isAuthenticated {
                    loadTodayGoogleEvents()
                }
            }

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

    // MARK: - Google Helpers
    private func loadTodayGoogleEvents() {
        guard googleCalendarService.isAuthenticated else { return }
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        Task {
            isLoadingGoogleEvents = true
            do {
                let events = try await googleCalendarService.fetchEvents(from: start, to: end)
                await MainActor.run {
                    self.googleTodayEvents = events
                    self.isLoadingGoogleEvents = false
                }
            } catch {
                await MainActor.run { self.isLoadingGoogleEvents = false }
                print("오늘 Google 일정 로드 실패: \(error)")
            }
        }
    }

    private func googleEventTimeRange(_ start: Date, _ end: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateStyle = .none
        df.timeStyle = .short
        return "\(df.string(from: start)) - \(df.string(from: end))"
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
