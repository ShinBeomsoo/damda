import SwiftUI

struct CardListView: View {
    @ObservedObject var cardManager: CardManagerObservable
    @State private var question: String = ""
    @State private var answer: String = ""

    let rowHeight: CGFloat = 80
    let visibleRows: CGFloat = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("암기 카드 관리")
                .font(.headline)
            HStack {
                TextField("질문(앞면)", text: $question)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("답변(뒷면)", text: $answer)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("추가") {
                    guard !question.isEmpty && !answer.isEmpty else { return }
                    cardManager.addCard(question: question, answer: answer)
                    question = ""
                    answer = ""
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 8)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(cardManager.cards, id: \ .objectID) { card in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.question ?? "")
                                .font(.body).bold()
                                .foregroundColor(.black)
                            Text(card.answer ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            HStack {
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
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
                        .padding(.horizontal, 2)
                        .frame(height: rowHeight)
                    }
                }
            }
            .frame(height: rowHeight * visibleRows)
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }
}