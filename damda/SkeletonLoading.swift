import SwiftUI

struct SkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
            )
            .allowsHitTesting(false)
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

struct SkeletonCard: View {
    let height: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonView()
                .frame(height: 20)
            SkeletonView()
                .frame(height: 16)
            SkeletonView()
                .frame(height: 16)
        }
        .padding()
        .frame(height: height)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SkeletonTimerCard: View {
    var body: some View {
        VStack(spacing: 16) {
            SkeletonView()
                .frame(height: 24)
            SkeletonView()
                .frame(height: 40)
            SkeletonView()
                .frame(width: 80, height: 32)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
} 