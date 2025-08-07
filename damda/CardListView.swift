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
                LazyVStack(spacing: 0) {
                    ForEach(cardManager.cards, id: \.objectID) { card in
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading) {
                                    if editingCardID == card.objectID {
                                        TextField("질문", text: $editingQuestion, onCommit: {
                                            cardManager.updateCard(card: card, newQuestion: editingQuestion, newAnswer: editingAnswer)
                                            editingCardID = nil
                                        })
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        TextField("답변", text: $editingAnswer, onCommit: {
                                            cardManager.updateCard(card: card, newQuestion: editingQuestion, newAnswer: editingAnswer)
                                            editingCardID = nil
                                        })
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .onDisappear {
                                            if editingCardID == card.objectID {
                                                cardManager.updateCard(card: card, newQuestion: editingQuestion, newAnswer: editingAnswer)
                                                editingCardID = nil
                                            }
                                        }
                                    } else {
                                        Text(card.question ?? "")
                                            .font(.body)
                                            .onTapGesture(count: 2) {
                                                editingCardID = card.objectID
                                                editingQuestion = card.question ?? ""
                                                editingAnswer = card.answer ?? ""
                                            }
                                        Text(card.answer ?? "")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .onTapGesture(count: 2) {
                                                editingCardID = card.objectID
                                                editingQuestion = card.question ?? ""
                                                editingAnswer = card.answer ?? ""
                                            }
                                    }
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
                            .frame(height: rowHeight)
                            Divider()
                        }
                    }
                }
            }
            .frame(height: rowHeight * visibleRows)
        }
        .padding()
    }
}