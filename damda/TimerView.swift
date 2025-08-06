//
//  TimerView.swift
//  damda
//
//  Created by SHIN BEOMSOO on 8/7/25.
//

import SwiftUI

struct TimerView: View {
    @ObservedObject var timerManager: TimerManagerObservable

    var body: some View {
        VStack {
            HStack(spacing: 24) {
                ForEach(TimerSession.allCases, id: \.self) { session in
                    VStack(spacing: 12) {
                        Text(sessionTitle(session))
                            .font(.headline)
                        Text(formatTime(timerManager.elapsedSeconds[session] ?? 0))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                        HStack {
                            Button(action: {
                                if timerManager.currentSession == session {
                                    timerManager.pause()
                                } else {
                                    timerManager.start(session: session)
                                }
                            }) {
                                Text(timerManager.currentSession == session ? "일시정지" : "시작")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                    .background(timerManager.currentSession == session ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            Button("리셋") {
                timerManager.reset()
            }
            .padding(.top, 24)
        }
        .padding()
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
