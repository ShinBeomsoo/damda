import SwiftUI

struct DeckManagementView: View {
    @ObservedObject var cardManager: CardManagerObservable
    @State private var newDeckName: String = ""
    @State private var renameDeckId: Int64? = nil
    @State private var renameText: String = ""
    @State private var showDeleteAlert: Bool = false
    @State private var pendingDeleteId: Int64? = nil
    @State private var pendingDeleteName: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("덱 관리")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                TextField("새 덱 이름", text: $newDeckName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("추가") {
                    let name = newDeckName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    cardManager.addDeck(name: name)
                    newDeckName = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(newDeckName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(cardManager.decks, id: \.objectID) { deck in
                        let did = (deck.value(forKey: "id") as? NSNumber)?.int64Value ?? (deck.value(forKey: "id") as? Int64)
                        let name = (deck.value(forKey: "name") as? String) ?? "이름 없음"
                        HStack(spacing: 8) {
                            if renameDeckId == did {
                                TextField("덱 이름", text: $renameText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button("저장") {
                                    let t = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !t.isEmpty, let did = did else { return }
                                    cardManager.renameDeck(id: did, newName: t)
                                    renameDeckId = nil
                                    renameText = ""
                                }
                                .buttonStyle(.bordered)
                                Button("취소") {
                                    renameDeckId = nil
                                    renameText = ""
                                }
                                .buttonStyle(.bordered)
                            } else {
                                Text(name)
                                    .font(.body)
                                Spacer()
                                Button {
                                    renameDeckId = did
                                    renameText = name
                                } label: {
                                    Label("이름 변경", systemImage: "pencil")
                                }
                                .buttonStyle(.bordered)
                                Button(role: .destructive) {
                                    pendingDeleteId = did
                                    pendingDeleteName = name
                                    showDeleteAlert = true
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .alert("정말 삭제하시겠습니까?", isPresented: $showDeleteAlert) {
            Button("삭제", role: .destructive) {
                if let id = pendingDeleteId { cardManager.deleteDeck(id: id) }
                pendingDeleteId = nil
                pendingDeleteName = ""
            }
            Button("취소", role: .cancel) {
                pendingDeleteId = nil
                pendingDeleteName = ""
            }
        } message: {
            Text("덱 \"\(pendingDeleteName)\" 을(를) 삭제하면 카드들은 미지정으로 이동합니다.")
        }
    }
}

