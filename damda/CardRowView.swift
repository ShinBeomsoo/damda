import SwiftUI

struct CardRowView: View {
    let card: Card
    let rowHeight: CGFloat
    @Binding var editingCardID: NSManagedObjectID?
    @Binding var editingQuestion: String
    @Binding var editingAnswer: String
    var cardManager: CardManagerObservable

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
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
                            .lineLimit(3)
                            .onTapGesture(count: 2) {
                                editingCardID = card.objectID
                                editingQuestion = card.question ?? ""
                                editingAnswer = card.answer ?? ""
                            }
                        Text(card.answer ?? "")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
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
            .padding(12)
        }
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
        .frame(maxWidth: .infinity)
        .frame(height: rowHeight)
    }
}