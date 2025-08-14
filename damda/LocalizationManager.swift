import Foundation

final class LocalizationManager {
    static let shared = LocalizationManager()

    private init() {}

    private var selectedCode: String {
        if let code = UserDefaults.standard.string(forKey: "appLanguageCode"), !code.isEmpty {
            return code
        }
        return Locale.preferredLanguages.first ?? "ko"
    }

    // Fallback in-app dictionary for immediate switch when .lproj isn't bundled or key missing
    private let enFallback: [String: String] = {
        let pairs: [(String, String)] = [
            // Units / Common words
            ("일", " days"),
            ("개", " items"),
            ("시간", "h"),
            ("분", "m"),
            ("기록", "Record"),
            ("할 일 완료", "Completed Todos"),
            ("할 일 미완료", "Uncompleted Todos"),
            // MainView labels
            ("공부 시간", "Study Time"),
            ("연속 달성", "Streak"),
            ("최대", "Max"),
            // MainView goals
            ("오늘의 목표", "Today's Goals"),
            ("오늘의 공부 시간", "Today's Study Time"),
            ("총 시간", "Total"),
            ("목표 달성", "Goal Progress"),
            ("세션별", "By Session"),
            ("우선순위 할 일", "Priority Todos"),
            ("모든 할 일 완료!", "All todos completed!"),
            ("학습 통계", "Study Statistics"),
            ("완료된 할 일", "Completed Todos"),
            ("할 일 관리", "Todo Management"),
            ("새로운 할 일 추가", "Add New Todo"),
            ("할 일을 입력하세요", "Enter your todo"),
            ("오늘의 할 일", "Today's Todos"),
            ("암기카드 관리", "Flashcard Management"),
            // Goals edit UI
            ("목표 설정", "Edit Goals"),
            ("공부 시간 목표", "Study Time Goal"),
            ("할 일 목표", "Todo Goal"),
            ("시", "h"),
            ("분", "m"),
            ("프리셋", "Presets"),
            ("기본값으로", "Reset to default"),
            ("4시간", "4h"),
            ("6시간", "6h"),
            ("8시간", "8h"),
            // Common/Sidebar
            ("학습 관리 앱", "Study Management App"),
            ("다크모드", "Dark Mode"),
            ("라이트모드", "Light Mode"),
            ("언어", "Language"),
            ("한국어", "Korean"),
            ("English", "English"),
            ("오늘", "Today"),
            ("통계", "Statistics"),
            ("할 일", "Todos"),
            ("암기카드", "Flashcards"),
            ("덱 관리", "Decks"),
            ("하루 마감", "End of Day"),
            ("자동 하루 마감", "Auto End of Day"),
            // Timer
            ("학습 시간", "Study Time"),
            ("리셋", "Reset"),
            ("취소", "Cancel"),
            ("타이머 리셋", "Reset Timer"),
            ("모든 세션의 시간을 0으로 초기화하시겠습니까?", "Do you want to reset all session times to 0?"),
            ("아침", "Morning"),
            ("오후", "Afternoon"),
            ("저녁", "Evening"),
            ("시작", "Start"),
            ("일시정지", "Pause"),
            ("실행 중", "Running"),
            // Flashcards
            ("오늘 복습할 암기 카드", "Today's Review Cards"),
            ("질문 없음", "No question"),
            ("답변 없음", "No answer"),
            ("답 보기", "Show Answer"),
            ("모름", "Don't Know"),
            ("애매함", "Ambiguous"),
            ("알고 있음", "Know"),
            ("오늘 복습할 카드가 없습니다!", "No cards to review today!"),
            ("새로운 카드를 추가하거나 내일 다시 확인해보세요.", "Add new cards or check back tomorrow."),
            // Card list / Decks
            ("암기 카드 관리", "Flashcard Management"),
            ("모든 덱", "All Decks"),
            ("이름 없음", "No name"),
            ("덱", "Deck"),
            ("카드 검색...", "Search cards..."),
            ("질문(앞면)", "Question (Front)"),
            ("답변(뒷면)", "Answer (Back)"),
            ("미지정", "Unassigned"),
            ("추가", "Add"),
            ("새 덱 이름", "New Deck Name"),
            ("덱 이름", "Deck Name"),
            ("저장", "Save"),
            ("이름 변경", "Rename"),
            ("삭제", "Delete"),
            ("정말 삭제하시겠습니까?", "Are you sure you want to delete?"),
            ("덱 \"%@\" 을(를) 삭제하면 카드들은 미지정으로 이동합니다.", "Deleting deck \"%@\" will move cards to Unassigned."),
            // Stats
            ("통계", "Statistics"),
            ("날짜", "Date"),
            ("집중 시간(분)", "Focused Time (min)"),
            ("최근 7일 집중 시간", "Last 7 Days Focused Time"),
            ("완료 개수", "Completed Count"),
            ("최근 7일 할 일 완료 개수", "Last 7 Days Completed Todos"),
        ]
        var dict: [String: String] = [:]
        for (k, v) in pairs { dict[k] = v }
        return dict
    }()

    func localized(_ key: String) -> String {
        // Try specific language bundle first
        if let path = Bundle.main.path(forResource: selectedCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            let value = bundle.localizedString(forKey: key, value: nil, table: nil)
            if selectedCode.hasPrefix("en") {
                // If not translated via bundle, fallback to in-app map
                return value == key ? (enFallback[key] ?? key) : value
            }
            return value
        }
        // Fallback to system resolution
        if selectedCode.hasPrefix("en") { return enFallback[key] ?? key }
        return NSLocalizedString(key, comment: "")
    }
}


