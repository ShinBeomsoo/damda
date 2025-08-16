import Foundation
import AppKit
import GoogleSignIn

@MainActor
class GoogleCalendarService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let calendarID = "primary"
    
    // MARK: - Initialization
    init() {
        setupGoogleSignIn()
    }
    
    // MARK: - Setup
    private func setupGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientID = plist["CLIENT_ID"] as? String else {
            print("GoogleService-Info.plist 파일을 찾을 수 없거나 CLIENT_ID가 없습니다.")
            print("Google Cloud Console에서 설정 파일을 다운로드하여 프로젝트에 추가해주세요.")
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
    }
    
    // MARK: - Authentication
    func authenticate() async throws -> Bool {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            // macOS에서는 restorePreviousSignIn을 먼저 시도
            let previousUser = GIDSignIn.sharedInstance.currentUser
            if previousUser != nil {
                self.isAuthenticated = true
                return true
            }
            
            // 새로운 인증 시도 - macOS에서는 NSWindow가 필요
            guard let window = NSApplication.shared.windows.first else {
                throw GoogleCalendarError.authenticationFailed
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
            
            // result.user는 GIDGoogleUser 타입이므로 nil 체크만 하면 됨
            guard result.user != nil else {
                throw GoogleCalendarError.authenticationFailed
            }
            
            // Google SignIn 성공
            self.isAuthenticated = true
            
            return true
        } catch {
            self.errorMessage = "Google Calendar 인증 실패: \(error.localizedDescription)"
            throw GoogleCalendarError.authenticationFailed
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        self.isAuthenticated = false
    }
    
    // MARK: - Calendar Operations (Google Calendar API는 나중에 구현)
    func fetchEvents(from startDate: Date, to endDate: Date) async throws -> [CalendarEvent] {
        // TODO: Google Calendar API 구현
        throw GoogleCalendarError.notImplemented
    }
    
    func createEvent(title: String, startDate: Date, endDate: Date, description: String?) async throws -> CalendarEvent {
        // TODO: Google Calendar API 구현
        throw GoogleCalendarError.notImplemented
    }
    
    func updateEvent(id: String, title: String, description: String?) async throws -> CalendarEvent {
        // TODO: Google Calendar API 구현
        throw GoogleCalendarError.notImplemented
    }
    
    func deleteEvent(id: String) async throws -> Bool {
        // TODO: Google Calendar API 구현
        throw GoogleCalendarError.notImplemented
    }
    
    // MARK: - Integration Methods
    func createEventFromTodo(_ todo: NSManagedObject) async throws -> CalendarEvent {
        // TODO: Google Calendar API 구현
        throw GoogleCalendarError.notImplemented
    }
    
    func createEventFromTimerRecord(_ record: NSManagedObject) async throws -> CalendarEvent {
        // TODO: Google Calendar API 구현
        throw GoogleCalendarError.notImplemented
    }
    
    // MARK: - Helper Methods
    private func getRootViewController() -> NSViewController {
        // macOS에서는 NSApplication을 통해 윈도우에 접근
        guard let window = NSApplication.shared.windows.first,
              let windowController = window.windowController,
              let contentViewController = windowController.contentViewController else {
            fatalError("Root view controller를 찾을 수 없습니다.")
        }
        return contentViewController
    }
}

// MARK: - Error Types
enum GoogleCalendarError: LocalizedError {
    case notAuthenticated
    case authenticationFailed
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Google Calendar에 인증되지 않았습니다."
        case .authenticationFailed:
            return "Google Calendar 인증에 실패했습니다."
        case .notImplemented:
            return "Google Calendar API 기능이 아직 구현되지 않았습니다."
        }
    }
}

// MARK: - Calendar Event Model
struct CalendarEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let description: String?
    
    static func == (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
        return lhs.id == rhs.id
    }
}
