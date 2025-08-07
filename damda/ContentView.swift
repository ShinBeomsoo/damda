//
//  ContentView.swift
//  damda
//
//  Created by SHIN BEOMSOO on 8/6/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var cardManager = CardManagerObservable(context: PersistenceController.shared.container.viewContext)
    @StateObject private var timerManager = TimerManagerObservable(context: PersistenceController.shared.container.viewContext)
    @StateObject private var todoManager = TodoManagerObservable(context: PersistenceController.shared.container.viewContext)
    @StateObject private var streakManager = StreakManagerObservable(context: PersistenceController.shared.container.viewContext)
    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
                .frame(width: 180)
            Divider()
            MainView(
                cardManager: cardManager,
                timerManager: timerManager,
                todoManager: todoManager,
                streakManager: streakManager
            )
            .frame(minWidth: 600, maxWidth: .infinity)
            Divider()
            DayDetailSidebarView()
                .frame(width: 320)
        }
        .frame(minWidth: 1100, minHeight: 700)
    }
}

struct SidebarView: View {
    var body: some View {
        VStack {
            Text("Sidebar")
            Spacer()
        }
    }
}

struct GoalSummaryView: View {
    @ObservedObject var timerManager: TimerManagerObservable
    @ObservedObject var todoManager: TodoManagerObservable
    @ObservedObject var streakManager: StreakManagerObservable

    let goalSeconds = 6 * 60 * 60 // 6시간
    let goalTodos = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("오늘의 목표")
                .font(.title2).bold()
            // 공부 시간 목표 ProgressBar
            HStack {
                Text("공부 시간: \(formatTime(timerManager.totalSeconds)) / 06:00:00")
                Spacer()
                Text("\(Int(Double(timerManager.totalSeconds) / Double(goalSeconds) * 100))%")
            }
            ProgressView(value: min(Double(timerManager.totalSeconds) / Double(goalSeconds), 1.0))
                .progressViewStyle(LinearProgressViewStyle())
            // 할 일 목표 ProgressBar
            HStack {
                Text("할 일: \(todoManager.completedCount) / \(goalTodos)")
                Spacer()
                Text("\(Int(Double(todoManager.completedCount) / Double(goalTodos) * 100))%")
            }
            ProgressView(value: min(Double(todoManager.completedCount) / Double(goalTodos), 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "E06552")))
            // 연속 달성(streak) 표시
            Text("연속 달성: \(streakManager.currentStreak)일 (최대: \(streakManager.maxStreak)일)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
    }
    func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 8:
            (a, r, g, b) = ((int & 0xFF000000) >> 24, (int & 0x00FF0000) >> 16, (int & 0x0000FF00) >> 8, int & 0x000000FF)
        case 6:
            (a, r, g, b) = (255, (int & 0xFF0000) >> 16, (int & 0x00FF00) >> 8, int & 0x0000FF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct TimerSectionView: View {
    @ObservedObject var timerManager: TimerManagerObservable
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("학습 시간")
                .font(.headline)
            HStack(spacing: 24) {
                ForEach([TimerSession.morning, TimerSession.afternoon, TimerSession.evening], id: \.self) { session in
                    VStack {
                        Text(sessionTitle(session))
                            .font(.system(size: 16))
                        Text(formatTime(timerManager.elapsedSeconds[session] ?? 0))
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                        Button(action: {
                            if timerManager.currentSession == session {
                                timerManager.pause()
                            } else {
                                timerManager.start(session: session)
                            }
                        }) {
                            Text(timerManager.currentSession == session ? "일시정지" : "시작")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color(hex: "E06552"))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            HStack {
                Spacer()
                Button(action: { timerManager.reset() }) {
                    Text("리셋")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 8)
                        .background(Color(hex: "E06552"))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
    }
    func sessionTitle(_ session: TimerSession) -> String {
        switch session {
        case .morning: return "아침"
        case .afternoon: return "오후"
        case .evening: return "저녁"
        }
    }
    func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

struct MainView: View {
    @ObservedObject var cardManager: CardManagerObservable
    @ObservedObject var timerManager: TimerManagerObservable
    @ObservedObject var todoManager: TodoManagerObservable
    @ObservedObject var streakManager: StreakManagerObservable
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                GoalSummaryView(
                    timerManager: timerManager,
                    todoManager: todoManager,
                    streakManager: streakManager
                )
                TimerSectionView(timerManager: timerManager)
                CardReviewView(cardManager: cardManager)
                CardListView(cardManager: cardManager)
                TodoListView(todoManager: todoManager)
                StatsChartView(
                    timeRecords: timerManager.dailyTimeRecords(forDays: 7),
                    todoRecords: todoManager.dailyCompletedTodos(forDays: 7)
                )
            }
            .padding()
        }
    }
}

struct DayDetailSidebarView: View {
    var body: some View {
        VStack {
            Text("Detail Sidebar")
            Spacer()
        }
    }
}
