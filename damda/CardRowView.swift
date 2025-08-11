import SwiftUI

struct CardRowView: View {
    @ObservedObject var card: Card
    let rowHeight: CGFloat
    @Binding var editingCardID: NSManagedObjectID?
    @Binding var editingQuestion: String
    @Binding var editingAnswer: String
    @ObservedObject var cardManager: CardManagerObservable

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
                // 덱 태그
                if let name = cardManager.deckName(for: card) {
                    Text(name)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(6)
                } else {
                    Text("미지정")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(6)
                }

                // 덱 지정 메뉴
                Menu {
                    Button("미지정") { cardManager.clearDeck(card: card) }
                    Divider()
                    ForEach(cardManager.decks, id: \.objectID) { deck in
                        let did = (deck.value(forKey: "id") as? NSNumber)?.int64Value ?? (deck.value(forKey: "id") as? Int64)
                        let isCurrent = {
                            let cid = (card.value(forKey: "deckId") as? NSNumber)?.int64Value ?? (card.value(forKey: "deckId") as? Int64)
                            return cid != nil && did != nil && cid == did
                        }()
                        Button(action: { if let did = did { cardManager.setDeck(card: card, deckId: did) } }) {
                            HStack {
                                Text((deck.value(forKey: "name") as? String) ?? "이름 없음")
                                if isCurrent { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "folder")
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)

                Button(action: { cardManager.deleteCard(card: card) }) {
                    Image(systemName: "trash")
                        .foregroundColor(.gray)
                }.buttonStyle(.plain)
            }
            .padding(12)
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                let label = cardManager.naturalDueLabel(for: card)
                Text("다음 복습: \(label)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding([.horizontal, .bottom], 12)
        }
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
        .frame(maxWidth: .infinity)
        .frame(height: rowHeight)
    }
}