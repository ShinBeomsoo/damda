import UserNotifications
import Foundation

struct NotificationInfo: Identifiable {
    let id = UUID()
    let identifier: String
    let title: String
    let body: String
    let hour: Int
    let minute: Int
    let isDefault: Bool
    
    var timeString: String {
        return String(format: "%02d:%02d", hour, minute)
    }
    
    var displayTitle: String {
        if isDefault {
            return "기본 알림 - \(timeString)"
        } else {
            return "사용자 정의 - \(timeString)"
        }
    }
}

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isNotificationsEnabled = false
    @Published var customNotificationTime: Date = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
    
    private init() {
        checkNotificationPermission()
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let wasEnabled = self.isNotificationsEnabled
                self.isNotificationsEnabled = settings.authorizationStatus == .authorized

                
                // 상태가 변경되었다면 UI 업데이트를 위해 objectWillChange 전송
                if wasEnabled != self.isNotificationsEnabled {
                    self.objectWillChange.send()
                }
            }
        }
    }
    
    func requestNotificationPermission() {

        
        // 현재 권한 상태 먼저 확인
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {

                
                switch settings.authorizationStatus {
                case .notDetermined:
                    // 권한이 결정되지 않은 경우에만 요청
                    self.requestAuthorization()
                case .denied:
                    // 권한이 거부된 경우 시스템 환경설정 안내

                    self.isNotificationsEnabled = false
                case .authorized:
                    // 이미 권한이 허용된 경우

                    self.isNotificationsEnabled = true
                    self.scheduleDefaultNotifications()
                case .provisional:
                    // 임시 권한

                    self.isNotificationsEnabled = true
                    self.scheduleDefaultNotifications()
                case .ephemeral:
                    // 일시적 권한

                    self.isNotificationsEnabled = true
                    self.scheduleDefaultNotifications()
                @unknown default:

                    self.isNotificationsEnabled = false
                }
                
                // 상태 업데이트를 위해 objectWillChange 전송
                self.objectWillChange.send()
            }
        }
    }
    
    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {

                self.isNotificationsEnabled = granted
                if granted {
                    self.scheduleDefaultNotifications()
                }
                // 권한 요청 후 상태 다시 확인
                self.checkNotificationPermission()
            }
        }
    }
    
    func scheduleDefaultNotifications() {
        // 점심 12시 알림
        scheduleNotification(
            identifier: "lunch-review",
            title: "복습 시간입니다!",
            body: "점심 시간에 복습할 암기카드가 기다리고 있어요.",
            hour: 12,
            minute: 0
        )
        
        // 저녁 6시 알림
        scheduleNotification(
            identifier: "dinner-review",
            title: "복습 시간입니다!",
            body: "저녁 시간에 복습할 암기카드가 기다리고 있어요.",
            hour: 18,
            minute: 0
        )
    }
    
    func scheduleCustomNotification(at date: Date) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        // 고유한 identifier 생성 (시간 기반)
        let identifier = "custom-review-\(hour)-\(minute)"
        

        
        scheduleNotification(
            identifier: identifier,
            title: "복습 시간입니다!",
            body: "설정한 시간에 복습할 암기카드가 기다리고 있어요.",
            hour: hour,
            minute: minute
        )
    }
    
    private func scheduleNotification(identifier: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "REVIEW_CATEGORY"
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        

        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    // 알림 스케줄링 오류 발생 (필요시 로깅)
                } else {
                    // 알림 스케줄링 성공
                }
            }
        }
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

    }
    
    func removeNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

    }
    
    func listScheduledNotifications(completion: @escaping ([NotificationInfo]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                var notificationInfos: [NotificationInfo] = []
                
                for request in requests {
                    if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                        let dateComponents = trigger.dateComponents
                        let hour = dateComponents.hour ?? 0
                        let minute = dateComponents.minute ?? 0
                        
                        let info = NotificationInfo(
                            identifier: request.identifier,
                            title: request.content.title,
                            body: request.content.body,
                            hour: hour,
                            minute: minute,
                            isDefault: request.identifier == "lunch-review" || request.identifier == "dinner-review"
                        )
                        notificationInfos.append(info)
                    }
                }
                
                // 시간순으로 정렬
                notificationInfos.sort { first, second in
                    if first.hour != second.hour {
                        return first.hour < second.hour
                    }
                    return first.minute < second.minute
                }
                
                completion(notificationInfos)
            }
        }
    }
    
    func setupNotificationCategories() {
        let reviewAction = UNNotificationAction(
            identifier: "REVIEW_ACTION",
            title: "복습하기",
            options: .foreground
        )
        
        let category = UNNotificationCategory(
            identifier: "REVIEW_CATEGORY",
            actions: [reviewAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
