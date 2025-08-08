import SwiftUI

struct TimerSectionView: View {
    @ObservedObject var timerManager: TimerManagerObservable
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("학습 시간")
                    .font(.headline)
                Spacer()
                Button(action: { timerManager.reset() }) {
                    Text("리셋")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color(hex: "E06552"))
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            HStack(spacing: 24) {
                ForEach([TimerSession.morning, TimerSession.afternoon, TimerSession.evening], id: \.self) { session in
                    TimerSessionCard(
                        session: session,
                        timerManager: timerManager
                    )
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
    }
}

struct TimerSessionCard: View {
    let session: TimerSession
    @ObservedObject var timerManager: TimerManagerObservable
    
    var body: some View {
        VStack {
            Text(sessionTitle(session))
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color(hex: "565D6D"))
                .lineSpacing(8)
            PulsingTimerView(
                isActive: timerManager.currentSession == session && timerManager.isRunning,
                timeString: formatTime(timerManager.elapsedSeconds[session] ?? 0)
            )
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
                    .buttonStyle(TimerButtonStyle(isActive: timerManager.currentSession == session))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func sessionTitle(_ session: TimerSession) -> String {
        switch session {
        case .morning: return "아침"
        case .afternoon: return "오후"
        case .evening: return "저녁"
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
} 