import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    let records: [Date: (todos: Int, seconds: Int, streak: Bool)]
    @StateObject private var googleCalendarService = GoogleCalendarService()
    @State private var googleEvents: [CalendarEvent] = []
    @State private var isLoadingEvents = false
    
    var body: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let year = calendar.component(.year, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        let firstOfMonth = calendar.date(from: components) ?? today
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth) ?? (1..<32)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let days: [Date] = range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)
        }
        let weekDays = ["일", "월", "화", "수", "목", "금", "토"]

        VStack(spacing: 12) {
            // 월/연도 헤더
            HStack {
                Button(action: {
                    if let prevMonth = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
                        selectedDate = prevMonth
                        loadGoogleEvents(for: prevMonth)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray)
                        .padding(6)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(Circle())
                }
                Spacer()
                Text("\(year, format: .number.grouping(.never))년 \(month, format: .number.grouping(.never))월")
                    .font(.pretendard(16, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                Button(action: {
                    if let nextMonth = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
                        selectedDate = nextMonth
                        loadGoogleEvents(for: nextMonth)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .padding(6)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, 2)
            
            // Google Calendar 연동 상태 표시
            if googleCalendarService.isAuthenticated {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("Google Calendar 연동됨")
                        .font(.pretendard(12))
                        .foregroundColor(.blue)
                    Spacer()
                    if isLoadingEvents {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            // 요일 헤더
            HStack {
                ForEach(weekDays, id: \.self) { wd in
                    Text(wd)
                        .font(.pretendard(12, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            let leadingEmpty = (firstWeekday + 6) % 7
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(0..<leadingEmpty, id: \.self) { _ in
                    Color.clear.frame(height: 44)
                }
                ForEach(days, id: \.self) { date in
                    let rec = records[calendar.startOfDay(for: date)]
                    let isToday = calendar.isDate(date, inSameDayAs: today)
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    let dayEvents = getEventsForDate(date)
                    
                    VStack(spacing: 3) {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.pretendard(14, weight: .bold))
                            .foregroundColor(isSelected ? .white : (isToday ? .orange : .black))
                            .frame(width: 32, height: 24)
                            .background(isSelected ? Color.orange : (isToday ? Color.orange.opacity(0.12) : Color.clear))
                            .cornerRadius(8)
                        
                        // damda 기록 표시
                        if let rec = rec {
                            HStack(spacing: 2) {
                                if rec.todos > 0 {
                                    Text("\(rec.todos)")
                                        .font(.pretendard(10, weight: .bold))
                                        .foregroundColor(.red)
                                }
                                if rec.seconds > 0 {
                                    Text("\(rec.seconds / 60)분")
                                        .font(.pretendard(10))
                                        .foregroundColor(.blue)
                                }
                                if rec.streak {
                                    Image(systemName: "flame.fill")
                                        .resizable()
                                        .frame(width: 10, height: 10)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        
                        // Google Calendar 이벤트 표시
                        if !dayEvents.isEmpty {
                            HStack(spacing: 2) {
                                ForEach(dayEvents.prefix(2), id: \.id) { event in
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                }
                                if dayEvents.count > 2 {
                                    Text("+\(dayEvents.count - 2)")
                                        .font(.pretendard(8))
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        
                        if rec == nil && dayEvents.isEmpty {
                            Spacer().frame(height: 10)
                        }
                    }
                    .frame(height: 44)
                    .background(isSelected ? Color.orange : Color.clear)
                    .cornerRadius(10)
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
        .onAppear {
            loadGoogleEvents(for: selectedDate)
        }
        .onChange(of: selectedDate) { _, newDate in
            loadGoogleEvents(for: newDate)
        }
    }
    
    // MARK: - Helper Methods
    private func loadGoogleEvents(for date: Date) {
        guard googleCalendarService.isAuthenticated else { return }
        
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let endOfMonth = calendar.dateInterval(of: .month, for: date)?.end ?? date
        
        Task {
            isLoadingEvents = true
            do {
                let events = try await googleCalendarService.fetchEvents(from: startOfMonth, to: endOfMonth)
                await MainActor.run {
                    self.googleEvents = events
                    self.isLoadingEvents = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingEvents = false
                }
                print("Google Calendar 이벤트 로드 실패: \(error)")
            }
        }
    }
    
    private func getEventsForDate(_ date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        return googleEvents.filter { event in
            event.startDate >= startOfDay && event.startDate < endOfDay
        }
    }
}