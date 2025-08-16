import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var customTime: Date = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
    @State private var showCustomNotificationSuccess = false
    @State private var scheduledNotifications: [NotificationInfo] = []
    
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
            
            // 사용자 정의 알림 시간
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizationManager.shared.localized("사용자 정의 알림 시간"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                DatePicker("", selection: $customTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                
                Button(action: {
                    notificationManager.scheduleCustomNotification(at: customTime)
                    showCustomNotificationSuccess = true
                    loadScheduledNotifications() // 알림 추가 후 목록 새로고침
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
            }
            
            Divider()
            
            // 알림 목록
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizationManager.shared.localized("알림 목록"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if scheduledNotifications.isEmpty {
                    Text(LocalizationManager.shared.localized("설정된 알림이 없습니다."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    VStack(spacing: 8) {
                        ForEach(scheduledNotifications) { notification in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(notification.displayTitle)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    Text(notification.body)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    notificationManager.removeNotification(withIdentifier: notification.identifier)
                                    loadScheduledNotifications()
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .font(.caption2)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 300, height: 400)
        .onAppear {
            loadScheduledNotifications()
        }
        .alert(LocalizationManager.shared.localized("알림 설정 완료"), isPresented: $showCustomNotificationSuccess) {
            Button(LocalizationManager.shared.localized("확인")) { }
        } message: {
            Text(LocalizationManager.shared.localized("사용자 정의 알림이 설정되었습니다."))
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


