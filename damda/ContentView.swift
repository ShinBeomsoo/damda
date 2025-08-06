//
//  ContentView.swift
//  damda
//
//  Created by SHIN BEOMSOO on 8/6/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var timerManager = TimerManagerObservable(context: PersistenceController.shared.container.viewContext)
    @StateObject private var todoManager = TodoManagerObservable(context: PersistenceController.shared.container.viewContext)

    let goalSeconds = 6 * 60 * 60 // 6시간
    let goalTodos = 5

    var body: some View {
        VStack(spacing: 32) {
            // 목표/진행률 UI
            VStack(alignment: .leading, spacing: 12) {
                Text("오늘의 목표")
                    .font(.title2).bold()
                HStack {
                    Text("공부 시간: \(formatTime(timerManager.totalSeconds)) / 06:00:00")
                    ProgressView(value: Double(timerManager.totalSeconds), total: Double(goalSeconds))
                        .frame(width: 150)
                    Text("\(Int(Double(timerManager.totalSeconds) / Double(goalSeconds) * 100))%")
                }
                HStack {
                    Text("할 일: \(todoManager.completedCount) / \(goalTodos)")
                    ProgressView(value: Double(todoManager.completedCount), total: Double(goalTodos))
                        .frame(width: 150)
                    Text("\(Int(Double(todoManager.completedCount) / Double(goalTodos) * 100))%")
                }
            }
            .padding()
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)

            TimerView(timerManager: timerManager)
            Divider()
            TodoListView(todoManager: todoManager)
        }
        .padding()
    }

    func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
