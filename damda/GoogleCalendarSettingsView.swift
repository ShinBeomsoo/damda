import SwiftUI

struct GoogleCalendarSettingsView: View {
    @StateObject private var googleCalendarService = GoogleCalendarService()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSyncEnabled = false
    @State private var syncTodos = true
    @State private var syncTimerRecords = true
    @State private var syncStudySessions = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            VStack(alignment: .leading, spacing: 8) {
                Text("Google Calendar 연동")
                    .font(.pretendard(24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("damda의 할 일과 공부 기록을 Google Calendar와 동기화하세요.")
                    .font(.pretendard(16))
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 인증 상태
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: googleCalendarService.isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(googleCalendarService.isAuthenticated ? .green : .red)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(googleCalendarService.isAuthenticated ? "연동됨" : "연동되지 않음")
                            .font(.pretendard(18, weight: .semibold))
                            .foregroundColor(googleCalendarService.isAuthenticated ? .green : .red)
                        
                        Text(googleCalendarService.isAuthenticated ? "Google Calendar와 성공적으로 연동되었습니다." : "Google Calendar 계정에 로그인하여 연동하세요.")
                            .font(.pretendard(14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if googleCalendarService.isAuthenticated {
                        Button("연동 해제") {
                            googleCalendarService.signOut()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    } else {
                        Button("Google 계정으로 로그인") {
                            Task {
                                await authenticateWithGoogle()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(googleCalendarService.isLoading)
                    }
                }
                
                if googleCalendarService.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("인증 중...")
                            .font(.pretendard(14))
                            .foregroundColor(.secondary)
                    }
                }
                
                if let errorMessage = googleCalendarService.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.pretendard(14))
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Divider()
            
            // 동기화 설정
            if googleCalendarService.isAuthenticated {
                VStack(alignment: .leading, spacing: 16) {
                    Text("동기화 설정")
                        .font(.pretendard(20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Google Calendar 동기화 활성화", isOn: $isSyncEnabled)
                            .font(.pretendard(16, weight: .medium))
                        
                        if isSyncEnabled {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle("할 일 동기화", isOn: $syncTodos)
                                    .font(.pretendard(14))
                                    .foregroundColor(.secondary)
                                
                                Toggle("타이머 기록 동기화", isOn: $syncTimerRecords)
                                    .font(.pretendard(14))
                                    .foregroundColor(.secondary)
                                
                                Toggle("공부 세션 동기화", isOn: $syncStudySessions)
                                    .font(.pretendard(14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 20)
                        }
                    }
                    
                    // 동기화 테스트 버튼
                    if isSyncEnabled {
                        Button("동기화 테스트") {
                            Task {
                                await testSync()
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(googleCalendarService.isLoading)
                    }
                }
                
                Divider()
                
                // 동기화 정보
                VStack(alignment: .leading, spacing: 12) {
                    Text("동기화 정보")
                        .font(.pretendard(20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        GoogleCalendarInfoRow(title: "마지막 동기화", value: "방금 전")
                        GoogleCalendarInfoRow(title: "동기화된 이벤트", value: "0개")
                        GoogleCalendarInfoRow(title: "동기화 상태", value: "정상")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .alert("알림", isPresented: $showAlert) {
            Button("확인") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Methods
    private func authenticateWithGoogle() async {
        do {
            let isAuthenticated = try await googleCalendarService.authenticate()
            if isAuthenticated {
                alertMessage = "Google Calendar와 성공적으로 연동되었습니다!"
                showAlert = true
            }
        } catch {
            alertMessage = "Google Calendar 연동에 실패했습니다: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func testSync() async {
        do {
            let events = try await googleCalendarService.fetchEvents(from: Date(), to: Date().addingTimeInterval(86400))
            alertMessage = "동기화 테스트 성공! 오늘 이벤트 \(events.count)개를 가져왔습니다."
            showAlert = true
        } catch {
            alertMessage = "동기화 테스트 실패: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - Info Row View
struct GoogleCalendarInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.pretendard(14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.pretendard(14, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    GoogleCalendarSettingsView()
}
