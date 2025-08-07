import SwiftUI

struct CardReviewView: View {
    @ObservedObject var cardManager: CardManagerObservable
    @State private var currentIndex: Int = 0
    @State private var showAnswer: Bool = false

    var reviewCards: [Card] {
        cardManager.todayReviewCards
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("오늘 복습할 암기 카드")
                .font(.headline)
            if reviewCards.isEmpty {
                Text("오늘 복습할 카드가 없습니다!")
                    .foregroundColor(.gray)
            } else {
                let card = reviewCards[currentIndex]
                VStack(spacing: 12) {
                    Text(card.question ?? "")
                        .font(.title2)
                    if showAnswer {
                        Text(card.answer ?? "")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                    Button(showAnswer ? "질문만 보기" : "답 보기") {
                        showAnswer.toggle()
                    }
                    .buttonStyle(.bordered)
                }
                HStack {
                    Button("모름") {
                        cardManager.review(card: card, result: .fail)
                        nextCard()
                    }
                    .buttonStyle(.bordered)
                    Button("애매함") {
                        cardManager.review(card: card, result: .medium)
                        nextCard()
                    }
                    .buttonStyle(.bordered)
                    Button("알고 있음") {
                        cardManager.review(card: card, result: .success)
                        nextCard()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }

    func nextCard() {
        showAnswer = false
        if currentIndex < reviewCards.count - 1 {
            currentIndex += 1
        } else {
            currentIndex = 0
        }
    }
}