import SwiftUI

struct AnimatedProgressBar: View {
    let value: Double
    let isCompleted: Bool
    @State private var animatedValue: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(isCompleted ? Color.green : Color(hex: "E06552"))
                    .frame(width: geometry.size.width * animatedValue, height: 8)
                    .animation(.easeInOut(duration: 1.0), value: animatedValue)
            }
        }
        .frame(height: 8)
        .onAppear {
            animatedValue = value
        }
        .onChange(of: value) { _, newValue in
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedValue = newValue
            }
        }
    }
}

struct PulsingTimerView: View {
    let isActive: Bool
    let timeString: String
    @State private var isAnimating: Bool = false
    
    var body: some View {
        Text(timeString)
            .font(.system(size: 30, weight: .heavy))
            .foregroundColor(Color(hex: "171A1F"))
            .lineSpacing(6)
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .animation(
                isAnimating ? 
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : 
                .easeInOut(duration: 0.3),
                value: isAnimating
            )
            .onAppear {
                // 뷰가 나타날 때마다 애니메이션 상태를 업데이트
                isAnimating = isActive
            }
            .onChange(of: isActive) { _, newValue in
                // isActive 상태가 변경될 때 애니메이션 상태 업데이트
                isAnimating = newValue
            }
    }
} 