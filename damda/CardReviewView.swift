import SwiftUI

struct CardReviewView: View {
    @ObservedObject var cardManager: CardManagerObservable
    @State private var showAnswer = false
    @State private var currentIndex: Int = 0

    // 임시 카드 데이터 (실제 연동 시 cardManager.todayReviewCards 등 사용)
    let cards: [Card] = [] // 실제 카드 데이터로 교체 필요

    var body: some View {
        VStack(spacing: 20) {
            Text("오늘 복습할 암기 카드")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                Text("React의 가상 DOM이란?")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .padding(.bottom, showAnswer ? 0 : 16)

                if showAnswer {
                    Text("실제 DOM과 달리, 변경 사항을 미리 메모리에 적용하는 가상의 트리 구조입니다.")
                        .font(.body)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 12)
                        .transition(.opacity)
                } else {
                    Button(action: { withAnimation { showAnswer = true } }) {
                        Text("답 보기")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color(hex: "E06552"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.bottom, 8)
                }
            }
            .frame(minWidth: 340, maxWidth: 480)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 8)

            HStack(spacing: 16) {
                Button("모름") {
                    // cardManager.review(card: card, result: .fail)
                }
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(8)
                Button("애매함") {
                    // cardManager.review(card: card, result: .medium)
                }
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "E06552"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "FBEBE8"))
                    .cornerRadius(8)
                Button("알고 있음") {
                    // cardManager.review(card: card, result: .success)
                }
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "E06552"))
                    .cornerRadius(8)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }
}