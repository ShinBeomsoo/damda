import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var customTime: Date = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
    @State private var showCustomNotificationSuccess = false
    @State private var scheduledNotifications: [NotificationInfo] = []
    @State private var showNotificationList = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text(LocalizationManager.shared.localized("알림 설정"))
                .font(.headline)
                .fontWeight(.bold)
            
            // 알림 권한 상태
            HStack {
                Image(systemName: notificationManager.isNotificationsEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(notificationManager.isNotificationsEnabled ? .green : .red)
                Text(notificationManager.isNotificationsEnabled ? LocalizationManager.shared.localized("알림 활성화됨") : LocalizationManager.shared.localized("알림 비활성화됨"))
                    .font(.caption)
                Spacer()
            }
            
            if !notificationManager.isNotificationsEnabled {
                VStack(spacing: 8) {
                    VStack(spacing: 8) {
                        Button(action: {
                            openSystemPreferences()
                        }) {
                            Text(LocalizationManager.shared.localized("알림 권한 요청"))
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("macOS 시스템 환경설정 > 알림 및 포커스에서 damda 앱의 알림을 허용해주세요.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            Divider()
            
            // 기본 알림 시간
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizationManager.shared.localized("기본 알림 시간"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("12:00")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("18:00")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(LocalizationManager.shared.localized("점심과 저녁에 복습 알림이 발송됩니다"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 사용자 정의 알림 시간
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizationManager.shared.localized("사용자 정의 알림 시간"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                DatePicker("", selection: $customTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                
                HStack(spacing: 8) {
                    Button(action: {
                        notificationManager.scheduleCustomNotification(at: customTime)
                        showCustomNotificationSuccess = true
                    }) {
                        Text(LocalizationManager.shared.localized("추가 알림 설정"))
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!notificationManager.isNotificationsEnabled)
                    
                    Button(action: {
                        loadScheduledNotifications()
                        showNotificationList = true
                    }) {
                        Text("알림 목록")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 300, height: 400)
        .alert("알림 설정 완료", isPresented: $showCustomNotificationSuccess) {
            Button("확인") { }
        } message: {
            Text("사용자 정의 알림이 설정되었습니다.")
        }
        .sheet(isPresented: $showNotificationList) {
            NotificationListView(
                notifications: scheduledNotifications,
                onDelete: { identifier in
                    notificationManager.removeNotification(withIdentifier: identifier)
                    loadScheduledNotifications()
                }
            )
        }
    }
    
    private func openSystemPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!
        NSWorkspace.shared.open(url)
    }
    
    private func loadScheduledNotifications() {
        notificationManager.listScheduledNotifications { notifications in
            self.scheduledNotifications = notifications
        }
    }
}

struct NotificationListView: View {
    let notifications: [NotificationInfo]
    let onDelete: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("알림 목록")
                .font(.headline)
                .fontWeight(.bold)
            
            if notifications.isEmpty {
                Text("설정된 알림이 없습니다.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(notifications) { notification in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(notification.displayTitle)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(notification.body)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                onDelete(notification.identifier)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 4)
                    }
                }
                .frame(height: 300)
            }
            
            HStack {
                Button("닫기") {
                    // sheet를 닫기 위해 외부에서 처리
                }
                .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                Spacer()
                
                Text("총 \(notifications.count)개의 알림")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 400, height: 450)
    }
}
