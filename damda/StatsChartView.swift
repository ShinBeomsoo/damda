//
//  StatsChartView.swift
//  damda
//
//  Created by SHIN BEOMSOO on 8/7/25.
//

import SwiftUI
import Charts

struct StatsChartView: View {
    let timeRecords: [(date: Date, seconds: Int)]
    let todoRecords: [(date: Date, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("최근 7일 집중 시간")
                .font(.headline)
            Chart {
                ForEach(timeRecords, id: \.date) { record in
                    LineMark(
                        x: .value("날짜", record.date, unit: .day),
                        y: .value("집중 시간(분)", record.seconds / 60)
                    )
                }
            }
            .frame(height: 180)

            Text("최근 7일 할 일 완료 개수")
                .font(.headline)
            Chart {
                ForEach(todoRecords, id: \.date) { record in
                    LineMark(
                        x: .value("날짜", record.date, unit: .day),
                        y: .value("완료 개수", record.count)
                    )
                }
            }
            .frame(height: 180)
        }
        .padding()
    }
}
