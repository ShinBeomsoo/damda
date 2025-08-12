//
//  StatsChartView.swift
//  damda
//
//  Created by SHIN BEOMSOO on 8/7/25.
//

import Charts
import SwiftUI

struct StatsChartView: View {
    let timeRecords: [(date: Date, seconds: Int)]
    let todoRecords: [(date: Date, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("통계")
                .font(.headline)
            Chart {
                ForEach(timeRecords, id: \.date) { record in
                    LineMark(
                        x: .value("날짜", record.date, unit: .day),
                        y: .value("집중 시간(분)", record.seconds / 60)
                    )
                    .foregroundStyle(Color.orange)
                }
            }
            .frame(height: 120)
            .chartYScale(domain: 0...max(timeRecords.map { $0.seconds / 60 }.max() ?? 60, 60))
            .padding(.bottom, 8)
            .overlay(Text("최근 7일 집중 시간").font(.caption), alignment: .topLeading)
            .allowsHitTesting(false)

            Chart {
                ForEach(todoRecords, id: \.date) { record in
                    LineMark(
                        x: .value("날짜", record.date, unit: .day),
                        y: .value("완료 개수", record.count)
                    )
                    .foregroundStyle(Color.blue)
                }
            }
            .frame(height: 120)
            .chartYScale(domain: 0...max(todoRecords.map { $0.count }.max() ?? 5, 5))
            .overlay(Text("최근 7일 할 일 완료 개수").font(.caption), alignment: .topLeading)
            .allowsHitTesting(false)
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
    }
}
