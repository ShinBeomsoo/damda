//
//  ContentView.swift
//  damda
//
//  Created by SHIN BEOMSOO on 8/6/25.
//

import SwiftUI
import CoreData

// 커스텀 폰트 확장
extension Font {
    static func pretendard(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .black: return Font.custom("Pretendard-Black", size: size)
        case .bold: return Font.custom("Pretendard-Bold", size: size)
        case .heavy: return Font.custom("Pretendard-ExtraBold", size: size)
        case .ultraLight: return Font.custom("Pretendard-ExtraLight", size: size)
        case .light: return Font.custom("Pretendard-Light", size: size)
        case .medium: return Font.custom("Pretendard-Medium", size: size)
        case .semibold: return Font.custom("Pretendard-SemiBold", size: size)
        case .thin: return Font.custom("Pretendard-Thin", size: size)
        default: return Font.custom("Pretendard-Regular", size: size)
        }
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var cardManager = CardManagerObservable(context: PersistenceController.shared.container.viewContext)
    @StateObject private var timerManager = TimerManagerObservable(context: PersistenceController.shared.container.viewContext)
    @StateObject private var todoManager = TodoManagerObservable(context: PersistenceController.shared.container.viewContext)
    @StateObject private var streakManager = StreakManagerObservable(context: PersistenceController.shared.container.viewContext)
    @AppStorage("appLanguageCode") private var appLanguageCode: String = Locale.preferredLanguages.first ?? "ko"
    @State private var selectedDate: Date = Date()
    @State private var showGoalAchievement = false
    @State private var selectedSidebarItem: SidebarItem = .today
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showRolloverDone = false
    @State private var showConfirmEndOfDay = false
    @AppStorage("autoEndOfDayEnabled", store: UserDefaults.environmentSpecific) private var autoEndOfDayEnabled = true
    @AppStorage("lastRolloverDay", store: UserDefaults.environmentSpecific) private var lastRolloverDay: Double = 0
    @State private var rolloverTimer: Timer?
    
    let goalSeconds = 6 * 60 * 60 // 6시간
    let goalTodos = 5
    
    var body: some View {
        HStack(spacing: 0) {
            SidebarView(
                selectedItem: $selectedSidebarItem,
                isDarkMode: $isDarkMode,
                autoEndOfDayEnabled: $autoEndOfDayEnabled,
                onRequestEndOfDay: { showConfirmEndOfDay = true }
            )
                .frame(width: 200)
            Divider()
            MainView(
                cardManager: cardManager,
                timerManager: timerManager,
                todoManager: todoManager,
                streakManager: streakManager,
                selectedItem: selectedSidebarItem
            )
            .frame(minWidth: 600, maxWidth: .infinity)
            Divider()
            DayDetailSidebarView(
                selectedDate: $selectedDate,
                todoManager: todoManager,
                timerManager: timerManager,
                streakManager: streakManager
            )
            .frame(width: 320)
        }
        .frame(minWidth: 1200, minHeight: 700)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .environment(\.locale, Locale(identifier: appLanguageCode))
        .id(appLanguageCode)
        .onChange(of: timerManager.totalSeconds) { _, _ in
            checkAndUpdateStreak()
        }
        .onChange(of: todoManager.completedCount) { _, _ in
            checkAndUpdateStreak()
        }
        .alert("🎉 목표 달성!", isPresented: $showGoalAchievement) {
            Button("확인") { }
        } message: {
            Text("오늘의 목표를 달성했습니다! 연속 달성이 증가했습니다.")
        }
        .alert("하루 마감", isPresented: $showConfirmEndOfDay) {
            Button("취소", role: .cancel) { }
            Button("마감", role: .destructive) { performEndOfDay() }
        } message: {
            Text("마감하면 어제 기록으로 저장되고 오늘은 초기화됩니다. 진행할까요?")
        }
        .onAppear {
            handleActivation()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                handleActivation()
            case .background:
                rolloverTimer?.invalidate()
                rolloverTimer = nil
            default:
                break
            }
        }
        .alert("하루 마감 완료", isPresented: $showRolloverDone) {
            Button("확인") { }
        } message: {
            Text("어제 기록이 저장되고 오늘로 초기화되었습니다.")
        }
    }
    
    private func checkAndUpdateStreak() {
        let wasGoalMet = streakManager.currentStreak > 0
        let isGoalMet = (timerManager.totalSeconds >= goalSeconds) && (todoManager.completedCount >= goalTodos)
        
        streakManager.markToday(success: isGoalMet)
        
        // 목표 달성 시 축하 메시지 표시
        if isGoalMet && !wasGoalMet {
            showGoalAchievement = true
        }
    }

    private var viewContext: NSManagedObjectContext { PersistenceController.shared.container.viewContext }

    private func performEndOfDay(now: Date = Date()) {
        RolloverCoordinator.endOfDay(
            now: now,
            timerManager: timerManager,
            todoManager: todoManager,
            streakManager: streakManager,
            context: viewContext
        )
        let start = Calendar.current.startOfDay(for: now)
        lastRolloverDay = start.timeIntervalSince1970
        showRolloverDone = true
    }

    private func handleActivation() {
        let todayStart = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        if lastRolloverDay != 0 && lastRolloverDay != todayStart {
            performEndOfDay()
        }
        lastRolloverDay = todayStart
        scheduleMidnightTimerIfNeeded()
    }

    private func scheduleMidnightTimerIfNeeded() {
        rolloverTimer?.invalidate()
        rolloverTimer = nil
        guard autoEndOfDayEnabled else { return }
        let cal = Calendar.current
        let now = Date()
        guard let nextMidnight = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) else { return }
        let interval = nextMidnight.timeIntervalSince(now)
        let timer = Timer.scheduledTimer(withTimeInterval: max(1, interval), repeats: false) { _ in
            performEndOfDay(now: nextMidnight)
            // 스냅샷 생성(어제 날짜 기준)
            if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: nextMidnight)) {
                todoManager.saveSnapshotForDay(yesterday)
            }
            scheduleMidnightTimerIfNeeded()
        }
        rolloverTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
}

enum SidebarItem: String, CaseIterable {
    case today = "today"
    case statistics = "statistics"
    case todos = "todos"
    case flashcards = "flashcards"
    case deckManagement = "deckManagement"
    
    var title: String {
        switch self {
        case .today: return LocalizationManager.shared.localized("오늘")
        case .statistics: return LocalizationManager.shared.localized("통계")
        case .todos: return LocalizationManager.shared.localized("할 일")
        case .flashcards: return LocalizationManager.shared.localized("암기카드")
        case .deckManagement: return LocalizationManager.shared.localized("덱 관리")
        }
    }
    
    var icon: String {
        switch self {
        case .today: return "house.fill"
        case .statistics: return "chart.line.uptrend.xyaxis"
        case .todos: return "checklist"
        case .flashcards: return "rectangle.on.rectangle"
        case .deckManagement: return "folder"
        }
    }
}

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem
    @Binding var isDarkMode: Bool
    @Binding var autoEndOfDayEnabled: Bool
    let onRequestEndOfDay: () -> Void
    @AppStorage("appLanguageCode") private var appLanguageCode: String = Locale.preferredLanguages.first ?? "ko"
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            VStack(spacing: 8) {
                Text("DAMDA")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "E06552"))
                Text(LocalizationManager.shared.localized("학습 관리 앱"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            // 다크모드 토글
            HStack {
                Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 14))
                    .foregroundColor(isDarkMode ? .yellow : .orange)
                Text(isDarkMode ? LocalizationManager.shared.localized("다크모드") : LocalizationManager.shared.localized("라이트모드"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    isDarkMode.toggle()
                }) {
                    Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                        .font(.system(size: 16))
                        .foregroundColor(isDarkMode ? .yellow : .orange)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.05))
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            
            // 메뉴 아이템들
            VStack(spacing: 4) {
                ForEach(SidebarItem.allCases, id: \.self) { item in
                    SidebarMenuItem(
                        item: item,
                        isSelected: selectedItem == item
                    ) {
                        selectedItem = item
                    }
                }
            }
            
            Spacer()

            Divider()
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 8) {
                // Language picker (instant apply)
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    Text(LocalizationManager.shared.localized("언어"))
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Picker("", selection: $appLanguageCode) {
                        Text(LocalizationManager.shared.localized("한국어")).tag("ko")
                        Text(LocalizationManager.shared.localized("English")).tag("en")
                    }
                    .frame(width: 120)
                    .pickerStyle(.menu)
                    .onChange(of: appLanguageCode) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "appLanguageCode")
                        // 즉시 리렌더 유도
                        selectedItem = selectedItem
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.05))
                )
                .frame(height: 28)
                Text(LocalizationManager.shared.localized("하루 마감"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)

                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    Text(LocalizationManager.shared.localized("자동 하루 마감"))
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Toggle("", isOn: $autoEndOfDayEnabled)
                        .toggleStyle(SwitchToggleStyle())
                        .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.05))
                )
                
                Button(action: onRequestEndOfDay) {
                    HStack {
                        Image(systemName: "tray.and.arrow.down.fill")
                        Text(LocalizationManager.shared.localized("하루 마감"))
                            .font(.system(size: 12, weight: .semibold))
                        Spacer()
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "E06552").opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(Color.gray.opacity(0.05))
    }
}

struct SidebarMenuItem: View {
    let item: SidebarItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 20)
                
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "E06552") : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
    }
}

struct GoalSummaryView: View {
    @ObservedObject var timerManager: TimerManagerObservable
    @ObservedObject var todoManager: TodoManagerObservable
    @ObservedObject var streakManager: StreakManagerObservable

    let goalSeconds = 6 * 60 * 60 // 6시간
    let goalTodos = 5
    
    @State private var animateProgress = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizationManager.shared.localized("오늘의 목표"))
                .font(.title2).bold()
            
            // 공부 시간 목표 ProgressBar
            VStack(spacing: 4) {
                HStack {
                    Text("\(LocalizationManager.shared.localized("공부 시간")): \(formatTime(timerManager.totalSeconds)) / 06:00:00")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(Double(timerManager.totalSeconds) / Double(goalSeconds) * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(timerManager.totalSeconds >= goalSeconds ? .green : .primary)
                }
                AnimatedProgressBar(
                    value: min(Double(timerManager.totalSeconds) / Double(goalSeconds), 1.0),
                    isCompleted: timerManager.totalSeconds >= goalSeconds
                )
            }
            
            // 할 일 목표 ProgressBar
            VStack(spacing: 4) {
                HStack {
                    Text("\(LocalizationManager.shared.localized("할 일")): \(todoManager.completedCount) / \(goalTodos)")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(Double(todoManager.completedCount) / Double(goalTodos) * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(todoManager.completedCount >= goalTodos ? .green : .primary)
                }
                AnimatedProgressBar(
                    value: min(Double(todoManager.completedCount) / Double(goalTodos), 1.0),
                    isCompleted: todoManager.completedCount >= goalTodos
                )
            }
            
            // 목표 달성 상태 표시
            if timerManager.totalSeconds >= goalSeconds && todoManager.completedCount >= goalTodos {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(LocalizationManager.shared.localized("오늘 목표 달성!"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Spacer()
                }
                .padding(.top, 4)
            }
            
            // 연속 달성(streak) 표시
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(LocalizationManager.shared.localized("연속 달성")): \(streakManager.currentStreak)\(LocalizationManager.shared.localized("일"))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(LocalizationManager.shared.localized("최대")): \(streakManager.maxStreak)\(LocalizationManager.shared.localized("일"))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animateProgress = true
            }
        }
    }
    
    func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

struct CustomProgressBar: View {
    let value: Double
    let isCompleted: Bool
    
    @State private var animatedValue: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 배경
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                // 진행 바
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isCompleted ? Color.green : Color(hex: "E06552"),
                                isCompleted ? Color.green.opacity(0.8) : Color(hex: "E06552").opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * animatedValue, height: 8)
                    .cornerRadius(4)
                    .animation(.easeInOut(duration: 0.6), value: animatedValue)
                
                // 완료 시 반짝이는 효과
                if isCompleted {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 20, height: 8)
                        .cornerRadius(4)
                        .offset(x: geometry.size.width * animatedValue - 20)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animatedValue)
                }
            }
        }
        .frame(height: 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedValue = value
            }
        }
        .onChange(of: value) { newValue in
            withAnimation(.easeInOut(duration: 0.6)) {
                animatedValue = newValue
            }
        }
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



struct MainView: View {
    @ObservedObject var cardManager: CardManagerObservable
    @ObservedObject var timerManager: TimerManagerObservable
    @ObservedObject var todoManager: TodoManagerObservable
    @ObservedObject var streakManager: StreakManagerObservable
    let selectedItem: SidebarItem
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                switch selectedItem {
                case .today:
                    TodayView(
                        cardManager: cardManager,
                        timerManager: timerManager,
                        todoManager: todoManager,
                        streakManager: streakManager
                    )
                case .statistics:
                    StatisticsView(
                        timerManager: timerManager,
                        todoManager: todoManager
                    )
                case .todos:
                    TodosView(todoManager: todoManager)
                case .flashcards:
                    FlashcardsView(cardManager: cardManager)
                case .deckManagement:
                    DeckManagementView(cardManager: cardManager)
                }
            }
            .padding()
        }
    }
}

struct TodayView: View {
    @ObservedObject var cardManager: CardManagerObservable
    @ObservedObject var timerManager: TimerManagerObservable
    @ObservedObject var todoManager: TodoManagerObservable
    @ObservedObject var streakManager: StreakManagerObservable
    
    var body: some View {
        VStack(spacing: 24) {
            GoalSummaryView(
                timerManager: timerManager,
                todoManager: todoManager,
                streakManager: streakManager
            )
            
            TimerSectionView(timerManager: timerManager)
            
            CardReviewView(cardManager: cardManager)
        }
    }
}

struct StatisticsView: View {
    @ObservedObject var timerManager: TimerManagerObservable
    @ObservedObject var todoManager: TodoManagerObservable
    
    var body: some View {
        VStack(spacing: 24) {
            Text(LocalizationManager.shared.localized("학습 통계"))
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            StatsChartView(
                timeRecords: timerManager.dailyTimeRecords(forDays: 7),
                todoRecords: todoManager.dailyCompletedTodos(forDays: 7)
            )
            
            // 추가 통계 정보들
            HStack(spacing: 24) {
                StatCard(
                    title: LocalizationManager.shared.localized("총 학습 시간"),
                    value: formatTime(timerManager.totalSeconds),
                    icon: "clock.fill",
                    color: .blue
                )
                
                StatCard(
                    title: LocalizationManager.shared.localized("완료된 할 일"),
                    value: "\(todoManager.completedCount)개",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return "\(h)시간 \(m)분"
    }
}

struct FlashcardsView: View {
    @ObservedObject var cardManager: CardManagerObservable
    
    var body: some View {
        VStack(spacing: 24) {
            Text(LocalizationManager.shared.localized("암기카드 관리"))
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 카드 추가 시 덱 선택 전용 메뉴를 전달
            CardListView(cardManager: cardManager)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TodosView: View {
    @ObservedObject var todoManager: TodoManagerObservable
    @State private var newTodoText: String = ""
    @State private var newTodoPriority: Int16 = 5
    
    var body: some View {
        VStack(spacing: 24) {
            Text(LocalizationManager.shared.localized("할 일 관리"))
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 할 일 입력
            VStack(spacing: 12) {
                Text(LocalizationManager.shared.localized("새로운 할 일 추가"))
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 12) {
                    TextField(LocalizationManager.shared.localized("할 일을 입력하세요"), text: $newTodoText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker(LocalizationManager.shared.localized("우선순위"), selection: $newTodoPriority) {
                        ForEach(1...10, id: \.self) { priority in
                            Text("\(priority)").tag(Int16(priority))
                        }
                    }
                    .frame(width: 80)
                    
                    Button(action: {
                        if !newTodoText.isEmpty {
                            todoManager.addTodo(text: newTodoText, priority: newTodoPriority)
                            newTodoText = ""
                            newTodoPriority = 5
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(hex: "E06552"))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
            
            // 할 일 목록
            TodoListView(todoManager: todoManager)
        }
    }
}



struct DayDetailSidebarView: View {
    @Binding var selectedDate: Date
    @ObservedObject var todoManager: TodoManagerObservable
    @ObservedObject var timerManager: TimerManagerObservable
    @ObservedObject var streakManager: StreakManagerObservable
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 오늘의 공부 시간 요약
                if Calendar.current.isDateInToday(selectedDate) {
                    TodayStudySummaryView(timerManager: timerManager)
                }
                
                // 우선순위 높은 할 일 3개
                if Calendar.current.isDateInToday(selectedDate) {
                    PriorityTodosView(todoManager: todoManager)
                }
                
                // 캘린더
                CalendarView(
                    selectedDate: $selectedDate,
                    records: makeRecords()
                )
                .frame(maxWidth: .infinity)
                
                // 선택된 날짜의 상세 기록
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(selectedDate, formatter: dateFormatter) \(LocalizationManager.shared.localized("기록"))")
                        .font(.pretendard(18, weight: .semibold))

                    let counts = todoManager.completedAndUncompletedCounts(on: selectedDate)
                    let completedList = todoManager.completedTodos(on: selectedDate)
                    let uncompletedList = todoManager.uncompletedTodos(on: selectedDate)
                    let seconds = timerManager.dailyTimeRecords(forDays: 30).first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) })?.seconds ?? 0
                    let streak = streakManager.currentStreak

                    // 1) 할 일 완료
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text(LocalizationManager.shared.localized("할 일 완료"))
                                .font(.subheadline).fontWeight(.semibold)
                            Spacer()
                            Text("\(counts.completed)\(LocalizationManager.shared.localized("개"))")
                                .font(.subheadline).foregroundColor(.secondary)
                        }
                        ForEach(completedList, id: \.objectID) { todo in
                            Text("- \(todo.text ?? "")").font(.subheadline)
                        }
                    }
                    Divider().opacity(0.2)

                    // 2) 할 일 미완료
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "circle").foregroundColor(.orange)
                            Text(LocalizationManager.shared.localized("할 일 미완료"))
                                .font(.subheadline).fontWeight(.semibold)
                            Spacer()
                            Text("\(counts.uncompleted)\(LocalizationManager.shared.localized("개"))")
                                .font(.subheadline).foregroundColor(.secondary)
                        }
                        ForEach(uncompletedList, id: \.objectID) { todo in
                            Text("- \(todo.text ?? "")").font(.subheadline)
                        }
                    }
                    Divider().opacity(0.2)

                    // 3) 학습 시간
                    HStack {
                        Image(systemName: "clock.fill").foregroundColor(.blue)
                        Text("\(LocalizationManager.shared.localized("학습 시간")): \(seconds / 3600)\(LocalizationManager.shared.localized("시간")) \((seconds % 3600) / 60)\(LocalizationManager.shared.localized("분"))")
                            .font(.subheadline)
                        Spacer()
                    }
                    Divider().opacity(0.2)

                    // 4) 연속 달성
                    HStack {
                        Image(systemName: "flame.fill").foregroundColor(.orange)
                        Text("\(LocalizationManager.shared.localized("연속 달성")): \(streak)\(LocalizationManager.shared.localized("일"))")
                            .font(.subheadline)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.gray.opacity(0.08))
                .cornerRadius(12)
            }
            .padding()
        }
    }
    
    func makeRecords() -> [Date: (todos: Int, seconds: Int, streak: Bool)] {
        let calendar = Calendar.current
        let goalSeconds = 6 * 60 * 60 // 6시간
        let goalTodos = 5

        // 범위: 현재 선택 월 기준 한 달
        let year = calendar.component(.year, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)
        let comps = DateComponents(year: year, month: month, day: 1)
        let start = calendar.date(from: comps) ?? calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start

        // CoreData에서 직접 집계
        let secondsByDay = timerManager.dailySecondsByDateRange(start: start, end: end)
        let todosByDay = todoManager.completedCountByDateRange(start: start, end: end)
        let streakByDay = streakManager.dailyStreakStatus(start: start, end: end)

        // 병합하여 결과 생성
        var result: [Date: (todos: Int, seconds: Int, streak: Bool)] = [:]
        
        // 해당 월의 모든 날짜에 대해 데이터 생성
        let range = calendar.range(of: .day, in: .month, for: start) ?? (1..<32)
        for dayOffset in 0..<range.count {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: start) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            
            let seconds = secondsByDay[startOfDay] ?? 0
            let todos = todosByDay[startOfDay] ?? 0
            let isStreakDay = streakByDay[startOfDay] ?? false
            
            result[startOfDay] = (todos: todos, seconds: seconds, streak: isStreakDay)
        }
        
        return result
    }
    
    var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = Locale(identifier: UserDefaults.standard.string(forKey: "appLanguageCode") ?? Locale.preferredLanguages.first ?? "ko")
        if df.locale.identifier.hasPrefix("en") {
            df.dateFormat = "yyyy MMM d"
        } else {
            df.dateFormat = "yyyy년 M월 d일"
        }
        return df
    }
}

struct TodayStudySummaryView: View {
    @ObservedObject var timerManager: TimerManagerObservable
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(Color(hex: "E06552"))
                Text(LocalizationManager.shared.localized("오늘의 공부 시간"))
                    .font(.pretendard(18, weight: .semibold))
                Spacer()
            }
            
            HStack(spacing: 16) {
                StudyTimeCard(
                    title: LocalizationManager.shared.localized("총 시간"),
                    time: formatTime(timerManager.totalSeconds),
                    icon: "clock.fill",
                    color: .blue
                )
                
                StudyTimeCard(
                    title: LocalizationManager.shared.localized("목표 달성"),
                    time: "\(Int(Double(timerManager.totalSeconds) / Double(6 * 60 * 60) * 100))%",
                    icon: "target",
                    color: timerManager.totalSeconds >= 6 * 60 * 60 ? .green : .orange
                )
            }
            
            // 세션별 시간
            VStack(spacing: 8) {
                HStack {
                    Text(LocalizationManager.shared.localized("세션별"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    SessionTimeCard(
                        title: LocalizationManager.shared.localized("아침"),
                        time: formatTime(timerManager.elapsedSeconds[.morning] ?? 0),
                        color: .orange
                    )
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    SessionTimeCard(
                        title: LocalizationManager.shared.localized("오후"),
                        time: formatTime(timerManager.elapsedSeconds[.afternoon] ?? 0),
                        color: .blue
                    )
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    SessionTimeCard(
                        title: LocalizationManager.shared.localized("저녁"),
                        time: formatTime(timerManager.elapsedSeconds[.evening] ?? 0),
                        color: .purple
                    )
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlColor))
        .cornerRadius(12)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return "\(h)\(LocalizationManager.shared.localized("시간")) \(m)\(LocalizationManager.shared.localized("분"))"
    }
}

struct StudyTimeCard: View {
    let title: String
    let time: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(time)
                .font(.pretendard(14, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.pretendard(10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct SessionTimeCard: View {
    let title: String
    let time: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.pretendard(10, weight: .medium))
                .foregroundColor(color)
            
            Text(time)
                .font(.pretendard(12, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
    }
}

struct PriorityTodosView: View {
    @ObservedObject var todoManager: TodoManagerObservable
    
    var priorityTodos: [Todo] {
        let uncompletedTodos = todoManager.todos.filter { !$0.isCompleted }
        return Array(uncompletedTodos.sorted { $0.priority > $1.priority }.prefix(3))
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(.orange)
                Text(LocalizationManager.shared.localized("우선순위 할 일"))
                    .font(.pretendard(18, weight: .semibold))
                Spacer()
            }
            
            if priorityTodos.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                    Text(LocalizationManager.shared.localized("모든 할 일 완료!"))
                        .font(.pretendard(14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(priorityTodos.enumerated()), id: \.element.objectID) { index, todo in
                        PriorityTodoRow(
                            todo: todo,
                            rank: index + 1,
                            todoManager: todoManager
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlColor))
        .cornerRadius(12)
    }
}

struct PriorityTodoRow: View {
    let todo: Todo
    let rank: Int
    @ObservedObject var todoManager: TodoManagerObservable
    
    var body: some View {
        HStack(spacing: 8) {
            // 순위 표시
            Text("\(rank)")
                .font(.pretendard(12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 16, height: 16)
                .background(
                    Circle()
                        .fill(rankColor)
                )
            
            // 우선순위 표시
            HStack(spacing: 2) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.orange)
                Text("\(todo.priority)")
                    .font(.pretendard(10, weight: .medium))
                    .foregroundColor(.orange)
            }
            
            // 할 일 텍스트
            Text(todo.text ?? "")
                .font(.pretendard(12))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // 완료 버튼
            Button(action: {
                todoManager.toggleComplete(todo: todo)
            }) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        default: return .gray
        }
    }
}
