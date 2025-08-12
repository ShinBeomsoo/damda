//
//  TimerView.swift
//  damda
//
//  Created by SHIN BEOMSOO on 8/7/25.
//

import SwiftUI

struct TimerView: View {
    @ObservedObject var timerManager: TimerManagerObservable
    @State private var showResetAlert = false
    @State private var showSessionInfo = false

    var body: some View {
        VStack(spacing: 16) {
            // 헤더
            HStack {
                Text("학습 시간")
                    .font(.pretendard(18, weight: .semibold))
                Spacer()
                Button(action: { showSessionInfo.toggle() }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            
            // 세션 카드들
            HStack(spacing: 24) {
                ForEach(Array(TimerSession.allCases), id: \.self) { (session: TimerSession) in
                    let isCurrent: Bool = (timerManager.currentSession == session)
                    let sec: Int = timerManager.elapsedSeconds[session] ?? 0
                    SessionCardView(
                        title: sessionTitle(session),
                        seconds: sec,
                        isCurrent: isCurrent,
                        onToggle: {
                            if isCurrent {
                                timerManager.pause()
                            } else {
                                timerManager.start(session: session)
                            }
                        }
                    )
                }
            }
            
            // 리셋 버튼
            Button("리셋") {
                showResetAlert = true
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            .padding(.top, 8)
        }
        .padding()
        .alert("타이머 리셋", isPresented: $showResetAlert) {
            Button("취소", role: .cancel) { }
            Button("리셋", role: .destructive) {
                timerManager.reset()
            }
        } message: {
            Text("모든 세션의 시간을 0으로 초기화하시겠습니까?")
        }
        .sheet(isPresented: $showSessionInfo) {
            SessionInfoView()
        }
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

private struct SessionCardView: View {
    let title: String
    let seconds: Int
    let isCurrent: Bool
    let onToggle: () -> Void
    
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 12) {
            // 상태 표시
            HStack {
                Text(title)
                    .font(.pretendard(16, weight: .semibold))
                Spacer()
                if isCurrent {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("실행 중")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // 시간 표시
            Text(formatTime(seconds))
                .font(.pretendard(28, weight: .bold))
                .foregroundColor(isCurrent ? .primary : .secondary)
            
            // 시작/일시정지 버튼
            Button(action: {
                onToggle()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isCurrent ? "pause.fill" : "play.fill")
                        .font(.pretendard(12, weight: .bold))
                    Text(isCurrent ? "일시정지" : "시작")
                        .font(.pretendard(14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: isCurrent ? 
                            [Color(hex: "E06552"), Color(hex: "F4A261")] :
                            [Color(hex: "E06552"), Color(hex: "E06552")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
                .shadow(
                    color: isCurrent ? Color.black.opacity(0.2) : Color.black.opacity(0.1),
                    radius: isCurrent ? 4 : 2,
                    x: 0,
                    y: isCurrent ? 2 : 1
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(minWidth: 180, maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrent ? Color(hex: "FBEBE8") : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrent ? Color(hex: "E06552").opacity(0.3) : Color.clear, lineWidth: 1)
                )
                .allowsHitTesting(false)
        )
        .shadow(color: isCurrent ? Color(hex: "E06552").opacity(0.2) : Color.black.opacity(0.05), radius: isCurrent ? 8 : 4, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.3), value: isCurrent)
    }

    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

struct SessionInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더
            HStack {
                Text("세션별 학습 시간 관리")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("닫기") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(title: "아침 세션", description: "새벽부터 오전까지의 학습 시간을 기록합니다.")
                InfoRow(title: "오후 세션", description: "점심 후부터 저녁 전까지의 학습 시간을 기록합니다.")
                InfoRow(title: "저녁 세션", description: "저녁부터 밤까지의 학습 시간을 기록합니다.")
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("사용법")
                    .font(.headline)
                    .padding(.top, 8)
                
                Text("• 각 세션의 '시작' 버튼을 눌러 타이머를 시작합니다")
                Text("• '일시정지' 버튼으로 타이머를 멈출 수 있습니다")
                Text("• 다른 세션을 시작하면 이전 세션은 자동으로 일시정지됩니다")
                Text("• '리셋' 버튼으로 모든 세션의 시간을 초기화할 수 있습니다")
                Text("• 학습 시간은 자동으로 저장되어 앱을 다시 실행해도 유지됩니다")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 500)
    }
}

struct InfoRow: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
