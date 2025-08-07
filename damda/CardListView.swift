import SwiftUI

struct CardListView: View {
    @ObservedObject var cardManager: CardManagerObservable
    @State private var question: String = ""
    @State private var answer: String = ""
    @State private var editingCardID: NSManagedObjectID? = nil
    @State private var editingQuestion: String = ""
    @State private var editingAnswer: String = ""

    let rowHeight: CGFloat = 50
    let visibleRows: CGFloat = 5

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

            // 리스트만 스크롤, 5개 row 높이 고정
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(cardManager.cards, id: \.objectID) { card in
                        CardRowView(
                            card: card,
                            rowHeight: rowHeight,
                            editingCardID: $editingCardID,
                            editingQuestion: $editingQuestion,
                            editingAnswer: $editingAnswer,
                            cardManager: cardManager
                        )
                    }
                }
            }
            .frame(height: rowHeight * visibleRows)
        }
        .padding()
    }
}