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
        let base = cardManager.cardsForSelectedDeck
        if searchText.isEmpty {
            return base
        } else {
            return base.filter { card in
                let question = card.question ?? ""
                let answer = card.answer ?? ""
                return question.localizedCaseInsensitiveContains(searchText) ||
                       answer.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localized("암기 카드 관리"))
                .font(.headline)
            // 덱 선택(필터)
            HStack(spacing: 8) {
                Menu {
                    Button(LocalizationManager.shared.localized("모든 덱")) { cardManager.selectedDeckId = nil }
                    Divider()
                    ForEach(cardManager.decks, id: \.objectID) { deck in
                        let did = (deck.value(forKey: "id") as? NSNumber)?.int64Value ?? (deck.value(forKey: "id") as? Int64)
                        let isSelected = (cardManager.selectedDeckId == did)
                        Button(action: { if let did = did { cardManager.selectedDeckId = did } }) {
                            HStack {
                                Text((deck.value(forKey: "name") as? String) ?? LocalizationManager.shared.localized("이름 없음"))
                                if isSelected { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "tray.full")
                        let currentName = cardManager.selectedDeckId.flatMap { did in
                            cardManager.decks.first(where: { ((($0.value(forKey: "id") as? NSNumber)?.int64Value ?? ($0.value(forKey: "id") as? Int64)) == did) })?.value(forKey: "name") as? String
                        }
                        Text(cardManager.selectedDeckId == nil ? LocalizationManager.shared.localized("모든 덱") : (currentName ?? LocalizationManager.shared.localized("덱")))
                    }
                }
                Spacer()
            }
            .padding(.bottom, 4)
            
            // 검색 바
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField(LocalizationManager.shared.localized("카드 검색..."), text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.bottom, 8)
            
            // 카드 추가: 덱 선택 전용
            HStack {
                TextField(LocalizationManager.shared.localized("질문(앞면)"), text: $question)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField(LocalizationManager.shared.localized("답변(뒷면)"), text: $answer)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Menu {
                    Button(LocalizationManager.shared.localized("미지정")) { cardManager.selectedDeckId = nil }
                    Divider()
                    ForEach(cardManager.decks, id: \.objectID) { deck in
                        let did = (deck.value(forKey: "id") as? NSNumber)?.int64Value ?? (deck.value(forKey: "id") as? Int64)
                        let name = (deck.value(forKey: "name") as? String) ?? LocalizationManager.shared.localized("이름 없음")
                        Button(action: { if let did = did { cardManager.selectedDeckId = did } }) { Text(name) }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                        Text(cardManager.selectedDeckId == nil ? LocalizationManager.shared.localized("미지정") : (cardManager.decks.first { ((($0.value(forKey: "id") as? NSNumber)?.int64Value ?? ($0.value(forKey: "id") as? Int64)) == cardManager.selectedDeckId) }?.value(forKey: "name") as? String) ?? LocalizationManager.shared.localized("덱"))
                    }
                }
                Button(LocalizationManager.shared.localized("추가")) {
                    guard !question.isEmpty && !answer.isEmpty else { return }
                    cardManager.addCard(question: question, answer: answer, deckId: cardManager.selectedDeckId)
                    question = ""
                    answer = ""
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 8)

            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
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