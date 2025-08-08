import SwiftUI

struct CardReviewView: View {
    @ObservedObject var cardManager: CardManagerObservable
    @State private var showAnswer = false
    @State private var currentIndex: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("오늘 복습할 암기 카드")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !cardManager.todayReviewCards.isEmpty {
                let currentCard = cardManager.todayReviewCards[currentIndex]
                
                VStack(spacing: 16) {
                    Text(currentCard.question ?? "질문 없음")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .padding(.bottom, showAnswer ? 0 : 16)

                    if showAnswer {
                        Text(currentCard.answer ?? "답변 없음")
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
                        cardManager.review(card: currentCard, result: .fail)
                        nextCard()
                    }
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.12))
                        .cornerRadius(8)
                    Button("애매함") {
                        cardManager.review(card: currentCard, result: .medium)
                        nextCard()
                    }
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "E06552"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "FBEBE8"))
                        .cornerRadius(8)
                    Button("알고 있음") {
                        cardManager.review(card: currentCard, result: .success)
                        nextCard()
                    }
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "E06552"))
                        .cornerRadius(8)
                }
                .padding(.top, 8)
                
                // 진행 상황 표시
                HStack {
                    Text("\(currentIndex + 1) / \(cardManager.todayReviewCards.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.top, 8)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("오늘 복습할 카드가 없습니다!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("새로운 카드를 추가하거나 내일 다시 확인해보세요.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(minWidth: 340, maxWidth: 480)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 8)
            }
        }
        .padding(24)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }
    
    private func nextCard() {
        showAnswer = false
        if currentIndex < cardManager.todayReviewCards.count - 1 {
            currentIndex += 1
        } else {
            // 모든 카드 복습 완료
            currentIndex = 0
        }
    }
}