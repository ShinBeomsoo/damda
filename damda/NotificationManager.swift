import UserNotifications
import Foundation

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
                print("🔔 알림 권한 상태 확인: \(settings.authorizationStatus.rawValue) -> \(self.isNotificationsEnabled)")
                
                // 상태가 변경되었다면 UI 업데이트를 위해 objectWillChange 전송
                if wasEnabled != self.isNotificationsEnabled {
                    self.objectWillChange.send()
                }
            }
        }
    }
    
    func requestNotificationPermission() {
        print("🔔 알림 권한 요청 시작")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                print("🔔 알림 권한 요청 결과: \(granted), 오류: \(error?.localizedDescription ?? "없음")")
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
        
        scheduleNotification(
            identifier: "custom-review",
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
            if let error = error {
                print("알림 스케줄링 오류: \(error)")
            }
        }
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
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
