import SwiftUI

struct CardListView: View {
    @ObservedObject var cardManager: CardManagerObservable
    @State private var question: String = ""
    @State private var answer: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("암기 카드 관리")
                .font(.headline)
            HStack {
                TextField("질문(앞면)", text: $question)
                TextField("답변(뒷면)", text: $answer)
                Button("추가") {
                    guard !question.isEmpty && !answer.isEmpty else { return }
                    cardManager.addCard(question: question, answer: answer)
                    question = ""
                    answer = ""
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 8)

            List {
                ForEach(cardManager.cards, id: \.objectID) { card in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(card.question ?? "")
                                .font(.body)
                            Text(card.answer ?? "")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: {
                            cardManager.deleteCard(card: card)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding()
    }
}