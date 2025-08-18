import Foundation
import AppKit
import CoreData
import GoogleSignIn

@MainActor
class GoogleCalendarService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let calendarID = "primary"
    private let baseURL = URL(string: "https://www.googleapis.com/calendar/v3")!
    
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
        
        let scopes = [
            "https://www.googleapis.com/auth/calendar",
            "https://www.googleapis.com/auth/calendar.events"
        ]
        
        do {
            if let current = GIDSignIn.sharedInstance.currentUser {
                // 필요한 스코프가 없다면 추가 요청
                if !(Set(current.grantedScopes ?? []).isSuperset(of: Set(scopes))) {
                    guard let window = NSApplication.shared.windows.first else {
                        throw GoogleCalendarError.authenticationFailed
                    }
                    _ = try await current.addScopes(scopes, presenting: window)
                }
                self.isAuthenticated = true
                return true
            }
            
            // 새로운 인증 시도 - macOS에서는 NSWindow가 필요
            guard let window = NSApplication.shared.windows.first else {
                throw GoogleCalendarError.authenticationFailed
            }
            
            let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
            var user = signInResult.user
            
            // 스코프 추가 (이미 부여되어 있지 않다면)
            if !(Set(user.grantedScopes ?? []).isSuperset(of: Set(scopes))) {
                let addResult = try await user.addScopes(scopes, presenting: window)
                user = addResult.user
            }
            
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
    
    // MARK: - Token
    private func refreshAndGetAccessToken() async throws -> String {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleCalendarError.notAuthenticated
        }
        return try await withCheckedThrowingContinuation { continuation in
            user.refreshTokensIfNeeded { refreshedUser, error in
                if let error = error {
                    continuation.resume(throwing: GoogleCalendarError.apiError(error.localizedDescription))
                    return
                }
                guard let token = refreshedUser?.accessToken.tokenString else {
                    continuation.resume(throwing: GoogleCalendarError.apiError("액세스 토큰을 가져오지 못했습니다"))
                    return
                }
                continuation.resume(returning: token)
            }
        }
    }
    
    // MARK: - Date Helpers
    private lazy var rfc3339WithFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
    
    private func parseRFC3339(_ value: String) -> Date? {
        if let d = rfc3339WithFraction.date(from: value) { return d }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f.date(from: value)
    }
    
    // MARK: - Calendar Operations (REST)
    func fetchEvents(from startDate: Date, to endDate: Date) async throws -> [CalendarEvent] {
        let token = try await refreshAndGetAccessToken()
        var components = URLComponents(url: baseURL.appendingPathComponent("calendars/\(calendarID)/events"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "timeMin", value: rfc3339WithFraction.string(from: startDate)),
            URLQueryItem(name: "timeMax", value: rfc3339WithFraction.string(from: endDate)),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime")
        ]
        guard let url = components.url else { throw GoogleCalendarError.apiError("URL 생성 실패") }
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GoogleCalendarError.apiError("HTTP 오류: \((resp as? HTTPURLResponse)?.statusCode ?? -1)")
        }
        
        let decoded = try JSONDecoder().decode(GoogleEventsResponse.self, from: data)
        let items = decoded.items ?? []
        
        return items.compactMap { ev in
            guard let id = ev.id, let title = ev.summary else { return nil }
            let startStr = ev.start?.dateTime ?? ev.start?.date
            let endStr = ev.end?.dateTime ?? ev.end?.date
            guard let s = startStr, let e = endStr, let sd = parseRFC3339(s), let ed = parseRFC3339(e) else { return nil }
            return CalendarEvent(id: id, title: title, startDate: sd, endDate: ed, description: ev.description)
        }
    }
    
    func createEvent(title: String, startDate: Date, endDate: Date, description: String?) async throws -> CalendarEvent {
        let token = try await refreshAndGetAccessToken()
        let url = baseURL.appendingPathComponent("calendars/\(calendarID)/events")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = GoogleEventWrite(
            summary: title,
            description: description,
            start: GoogleEventDateTime(dateTime: rfc3339WithFraction.string(from: startDate), timeZone: "UTC"),
            end: GoogleEventDateTime(dateTime: rfc3339WithFraction.string(from: endDate), timeZone: "UTC")
        )
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GoogleCalendarError.apiError("HTTP 오류: \((resp as? HTTPURLResponse)?.statusCode ?? -1)")
        }
        
        let item = try JSONDecoder().decode(GoogleEventItem.self, from: data)
        guard let id = item.id, let t = item.summary else { throw GoogleCalendarError.apiError("응답 파싱 실패") }
        let startStr = item.start?.dateTime ?? item.start?.date
        let endStr = item.end?.dateTime ?? item.end?.date
        guard let s = startStr, let e = endStr, let sd = parseRFC3339(s), let ed = parseRFC3339(e) else { throw GoogleCalendarError.apiError("날짜 파싱 실패") }
        
        return CalendarEvent(id: id, title: t, startDate: sd, endDate: ed, description: item.description)
    }
    
    func updateEvent(id: String, title: String, description: String?) async throws -> CalendarEvent {
        let token = try await refreshAndGetAccessToken()
        let url = baseURL.appendingPathComponent("calendars/\(calendarID)/events/\(id)")
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = GoogleEventWrite(summary: title, description: description, start: nil, end: nil)
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GoogleCalendarError.apiError("HTTP 오류: \((resp as? HTTPURLResponse)?.statusCode ?? -1)")
        }
        
        let item = try JSONDecoder().decode(GoogleEventItem.self, from: data)
        let startStr = item.start?.dateTime ?? item.start?.date
        let endStr = item.end?.dateTime ?? item.end?.date
        let sd = startStr.flatMap(parseRFC3339) ?? Date()
        let ed = endStr.flatMap(parseRFC3339) ?? Date()
        
        return CalendarEvent(id: item.id ?? id, title: item.summary ?? title, startDate: sd, endDate: ed, description: item.description ?? description)
    }
    
    func deleteEvent(id: String) async throws -> Bool {
        let token = try await refreshAndGetAccessToken()
        let url = baseURL.appendingPathComponent("calendars/\(calendarID)/events/\(id)")
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { return false }
        return http.statusCode == 204 || http.statusCode == 200
    }
    
    // MARK: - Integration Methods
    func createEventFromTodo(_ todo: NSManagedObject) async throws -> CalendarEvent {
        guard let title = todo.value(forKey: "title") as? String else {
            throw GoogleCalendarError.invalidData("Todo 제목을 찾을 수 없습니다")
        }
        let startDate = todo.value(forKey: "createdAt") as? Date ?? Date()
        let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        return try await createEvent(
            title: title,
            startDate: startDate,
            endDate: endDate,
            description: "damda Todo: \(title)"
        )
    }
    
    func createEventFromTimerRecord(_ record: NSManagedObject) async throws -> CalendarEvent {
        let desc = (record.value(forKey: "description") as? String) ?? "Study"
        let startDate = record.value(forKey: "startTime") as? Date ?? Date()
        let endDate = record.value(forKey: "endTime") as? Date ?? startDate
        return try await createEvent(
            title: "Study Session",
            startDate: startDate,
            endDate: endDate,
            description: "damda Study: \(desc)"
        )
    }
}

// MARK: - Error Types
enum GoogleCalendarError: LocalizedError {
    case authenticationFailed
    case notAuthenticated
    case notImplemented
    case apiError(String)
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Google Calendar 인증에 실패했습니다"
        case .notAuthenticated:
            return "Google Calendar에 인증되지 않았습니다"
        case .notImplemented:
            return "아직 구현되지 않은 기능입니다"
        case .apiError(let message):
            return "Google Calendar API 오류: \(message)"
        case .invalidData(let message):
            return "데이터 오류: \(message)"
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

// MARK: - Google Calendar REST DTOs
private struct GoogleEventsResponse: Decodable {
    let items: [GoogleEventItem]?
}

private struct GoogleEventItem: Decodable {
    let id: String?
    let summary: String?
    let description: String?
    let start: GoogleEventDate?
    let end: GoogleEventDate?
}

private struct GoogleEventDate: Decodable {
    let dateTime: String?
    let date: String?
}

private struct GoogleEventDateTime: Encodable {
    let dateTime: String
    let timeZone: String?
}

private struct GoogleEventWrite: Encodable {
    let summary: String?
    let description: String?
    let start: GoogleEventDateTime?
    let end: GoogleEventDateTime?
}
