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
    @StateObject private var streakManager = StreakManagerObservable(context: PersistenceController.shared.container.viewContext)
    @StateObject private var cardManager = CardManagerObservable(context: PersistenceController.shared.container.viewContext)
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false

    let goalSeconds = 6 * 60 * 60 // 6시간
    let goalTodos = 5

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView([.vertical, .horizontal], showsIndicators: true) {
                HStack(spacing: 0) {
                    // 왼쪽 50%: 목표, 타이머, 그래프
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 32) {
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
                                HStack {
                                    Text("연속 달성: \(streakManager.currentStreak)일 (최대: \(streakManager.maxStreak)일)")
                                        .font(.headline)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.08))
                            .cornerRadius(12)

                            TimerView(timerManager: timerManager)
                            StatsChartView(
                                timeRecords: timerManager.dailyTimeRecords(forDays: 7),
                                todoRecords: todoManager.dailyCompletedTodos(forDays: 7)
                            )
                        }
                        .frame(minWidth: 350, maxWidth: .infinity, alignment: .top)
                        .padding()
                    }
                    Divider()
                    // 오른쪽 50%: Todo 리스트 + 암기 카드
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            TodoListView(todoManager: todoManager)
                            CardReviewView(cardManager: cardManager)
                            CardListView(cardManager: cardManager)
                        }
                        .frame(minWidth: 350, maxWidth: .infinity, alignment: .top)
                        .padding()
                    }
                }
                .frame(minWidth: 700, minHeight: 500)
            }
            // 왼쪽 위 다크모드 토글 버튼
            Button(action: { isDarkMode.toggle() }) {
                Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    .imageScale(.large)
                    .foregroundColor(isDarkMode ? .yellow : .blue)
                    .padding(8)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .padding(.leading, 8)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
