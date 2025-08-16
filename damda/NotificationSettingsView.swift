import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var customTime: Date = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
    @State private var showCustomNotificationSuccess = false
    
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
                        notificationManager.listScheduledNotifications()
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
    }
    
    private func openSystemPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!
        NSWorkspace.shared.open(url)
    }
}
