import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    let records: [Date: (todos: Int, seconds: Int, streak: Bool)]

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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                Button(action: {
                    if let nextMonth = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
                        selectedDate = nextMonth
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
            // 요일 헤더
            HStack {
                ForEach(weekDays, id: \.self) { wd in
                    Text(wd)
                        .font(.system(size: 12, weight: .medium))
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
                    VStack(spacing: 3) {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isSelected ? .white : (isToday ? .orange : .black))
                            .frame(width: 32, height: 24)
                            .background(isSelected ? Color.orange : (isToday ? Color.orange.opacity(0.12) : Color.clear))
                            .cornerRadius(8)
                        if let rec = rec {
                            HStack(spacing: 2) {
                                if rec.todos > 0 {
                                    Text("\(rec.todos)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.red)
                                }
                                if rec.seconds > 0 {
                                    Text("\(rec.seconds / 60)분")
                                        .font(.system(size: 10))
                                        .foregroundColor(.blue)
                                }
                                if rec.streak {
                                    Image(systemName: "flame.fill")
                                        .resizable()
                                        .frame(width: 10, height: 10)
                                        .foregroundColor(.orange)
                                }
                            }
                        } else {
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
    }
}