import SwiftUI

struct CardListView: View {
    @ObservedObject var cardManager: CardManagerObservable
    @State private var question: String = ""
    @State private var answer: String = ""
    @State private var searchText: String = ""
    @State private var editingCardID: NSManagedObjectID? = nil
    @State private var editingQuestion: String = ""
    @State private var editingAnswer: String = ""

    let rowHeight: CGFloat = 80
    let visibleRows: CGFloat = 5

    var filteredCards: [Card] {
        if searchText.isEmpty {
            return cardManager.cards
        } else {
            return cardManager.cards.filter { card in
                let question = card.question ?? ""
                let answer = card.answer ?? ""
                return question.localizedCaseInsensitiveContains(searchText) ||
                       answer.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("암기 카드 관리")
                .font(.headline)
            
            // 검색 바
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("카드 검색...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.bottom, 8)
            
            // 카드 추가
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
                    ForEach(filteredCards, id: \.objectID) { card in
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
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }
}