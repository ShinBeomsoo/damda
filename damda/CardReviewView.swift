import SwiftUI

struct CardReviewView: View {
    @ObservedObject var cardManager: CardManagerObservable
    @State private var showAnswer = false
    @State private var currentIndex: Int = 0
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            Text(LocalizationManager.shared.localized("오늘 복습할 암기 카드"))
                .font(.pretendard(18, weight: .semibold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !cardManager.todayReviewCards.isEmpty {
                let currentCard = cardManager.todayReviewCards[currentIndex]
                
                VStack(spacing: 16) {
                    Text(currentCard.question ?? LocalizationManager.shared.localized("질문 없음"))
                        .font(.pretendard(20, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .padding(.bottom, showAnswer ? 0 : 16)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))

                    if showAnswer {
                        Text(currentCard.answer ?? LocalizationManager.shared.localized("답변 없음"))
                            .font(.pretendard(16))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 12)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                    } else {
                        Button(action: { 
                            withAnimation(.easeInOut(duration: 0.3)) { showAnswer = true } 
                        }) {
                            Text(LocalizationManager.shared.localized("답 보기"))
                                .font(.pretendard(14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color(hex: "E06552"))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.bottom, 8)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(minWidth: 340, maxWidth: 480)
                .background(Color.clear)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 8)

                HStack(spacing: 16) {
                    let preview = cardManager.previewInfos(for: currentCard)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            cardManager.review(card: currentCard, result: .fail)
                            nextCard()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text("\(LocalizationManager.shared.localized("모름")) · \(preview.fail.label)")
                            Image(systemName: "info.circle")
                                .help(preview.fail.tooltip)
                        }
                            .font(.pretendard(14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(hex: "FF6B6B"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .slideTransition(isVisible: true, direction: .left)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            cardManager.review(card: currentCard, result: .medium)
                            nextCard()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text("\(LocalizationManager.shared.localized("애매함")) · \(preview.medium.label)")
                            Image(systemName: "info.circle")
                                .help(preview.medium.tooltip)
                        }
                            .font(.pretendard(14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(hex: "FFA726"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .slideTransition(isVisible: true, direction: .up)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            cardManager.review(card: currentCard, result: .success)
                            nextCard()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text("\(LocalizationManager.shared.localized("알고 있음")) · \(preview.success.label)")
                            Image(systemName: "info.circle")
                                .help(preview.success.tooltip)
                        }
                            .font(.pretendard(14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(hex: "66BB6A"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .slideTransition(isVisible: true, direction: .right)
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
                        .font(.pretendard(48))
                        .foregroundColor(.green)
                    Text(LocalizationManager.shared.localized("오늘 복습할 카드가 없습니다!"))
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(LocalizationManager.shared.localized("새로운 카드를 추가하거나 내일 다시 확인해보세요."))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(minWidth: 340, maxWidth: 480)
                .padding(.horizontal, 8)
            }
        }
        .padding(24)
        .background(cardManager.todayReviewCards.isEmpty ? Color(NSColor.controlColor) : Color.gray.opacity(0.12))
        .cornerRadius(12)
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