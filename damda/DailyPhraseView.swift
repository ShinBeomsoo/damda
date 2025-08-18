import SwiftUI

final class DailyPhraseViewModel: ObservableObject {
    @Published var phrases: [DailyPhrase] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let service: DailyPhraseService

    init(service: DailyPhraseService) {
        self.service = service
    }

    func load(now: Date = Date()) {
        isLoading = true
        errorMessage = nil
        service.phrasesForTodayPair(now: now) { [weak self] phrases in
            DispatchQueue.main.async {
                self?.phrases = phrases
                self?.isLoading = false
                if phrases.isEmpty {
                    self?.errorMessage = LocalizationManager.shared.localized("문장을 불러오지 못했습니다")
                }
            }
        }
    }
}

struct DailyPhraseView: View {
    @StateObject private var viewModel: DailyPhraseViewModel

    init(remoteURL: String = "https://shinbeomsoo.github.io/damda/daily_phrases.json") {
        let provider = try? RemoteDailyPhraseProvider(urlString: remoteURL)
        let service = DailyPhraseService(provider: provider ?? (try! RemoteDailyPhraseProvider(urlString: remoteURL)))
        _viewModel = StateObject(wrappedValue: DailyPhraseViewModel(service: service))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "quote.bubble.fill")
                    .foregroundColor(Color(hex: "E06552"))
                Text(LocalizationManager.shared.localized("오늘의 영어"))
                    .font(.pretendard(16, weight: .semibold))
                Spacer()
            }

            if viewModel.isLoading {
                SkeletonCard(height: 42)
            } else if !viewModel.phrases.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(viewModel.phrases.prefix(2).enumerated()), id: \.offset) { _, p in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(p.en)
                                .font(.pretendard(14, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(p.ko)
                                .font(.pretendard(12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text(viewModel.errorMessage ?? LocalizationManager.shared.localized("데이터 없음"))
                    .font(.pretendard(12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .onAppear { viewModel.load() }
    }
}


