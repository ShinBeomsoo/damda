import SwiftUI

struct SettingsView: View {
    @Binding var isDarkMode: Bool
    @Binding var autoEndOfDayEnabled: Bool
    let onRequestEndOfDay: () -> Void
    @AppStorage("appLanguageCode") private var appLanguageCode: String = Locale.preferredLanguages.first ?? "ko"
    @State private var showNotificationSettings = false
    @State private var showGoalSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // 헤더
                VStack(spacing: 8) {
                    Text(LocalizationManager.shared.localized("설정"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(LocalizationManager.shared.localized("앱의 모든 설정을 관리합니다"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 일반 설정
                SettingsSection(
                    title: LocalizationManager.shared.localized("일반"),
                    icon: "gearshape.fill",
                    color: .blue
                ) {
                    VStack(spacing: 16) {
                        // 언어 설정
                        SettingsRow(
                            icon: "globe",
                            iconColor: .blue,
                            title: LocalizationManager.shared.localized("언어"),
                            subtitle: LocalizationManager.shared.localized("앱 언어를 선택하세요")
                        ) {
                            Picker("", selection: $appLanguageCode) {
                                Text(LocalizationManager.shared.localized("한국어")).tag("ko")
                                Text(LocalizationManager.shared.localized("English")).tag("en")
                            }
                            .pickerStyle(.menu)
                            .frame(width: 120)
                        }
                        
                        Divider()
                        
                        // 다크모드 설정
                        SettingsRow(
                            icon: isDarkMode ? "moon.fill" : "sun.max.fill",
                            iconColor: isDarkMode ? .yellow : .orange,
                            title: isDarkMode ? LocalizationManager.shared.localized("다크모드") : LocalizationManager.shared.localized("라이트모드"),
                            subtitle: LocalizationManager.shared.localized("테마를 선택하세요")
                        ) {
                            Button(action: {
                                isDarkMode.toggle()
                            }) {
                                Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(isDarkMode ? .yellow : .orange)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(Color.gray.opacity(0.1))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // 알림 설정
                SettingsSection(
                    title: LocalizationManager.shared.localized("알림"),
                    icon: "bell.fill",
                    color: .orange
                ) {
                    VStack(spacing: 16) {
                        SettingsRow(
                            icon: "bell.fill",
                            iconColor: .orange,
                            title: LocalizationManager.shared.localized("알림 설정"),
                            subtitle: LocalizationManager.shared.localized("복습 알림을 설정하세요")
                        ) {
                            Button(action: {
                                showNotificationSettings.toggle()
                            }) {
                                Text(LocalizationManager.shared.localized("설정"))
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // 학습 관리 설정
                SettingsSection(
                    title: LocalizationManager.shared.localized("학습 관리"),
                    icon: "calendar.badge.clock",
                    color: .green
                ) {
                    VStack(spacing: 16) {
                        // 자동 하루 마감
                        SettingsRow(
                            icon: "calendar.badge.clock",
                            iconColor: .blue,
                            title: LocalizationManager.shared.localized("자동 하루 마감"),
                            subtitle: LocalizationManager.shared.localized("자동으로 하루를 마감합니다")
                        ) {
                            Toggle("", isOn: $autoEndOfDayEnabled)
                                .toggleStyle(SwitchToggleStyle())
                                .labelsHidden()
                        }
                        
                        Divider()
                        
                        // 수동 하루 마감
                        SettingsRow(
                            icon: "tray.and.arrow.down.fill",
                            iconColor: Color(hex: "E06552"),
                            title: LocalizationManager.shared.localized("하루 마감"),
                            subtitle: LocalizationManager.shared.localized("지금 하루를 마감합니다")
                        ) {
                            Button(action: onRequestEndOfDay) {
                                Text(LocalizationManager.shared.localized("마감"))
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "E06552"))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // 목표 설정
                SettingsSection(
                    title: LocalizationManager.shared.localized("목표"),
                    icon: "target",
                    color: .purple
                ) {
                    VStack(spacing: 16) {
                        SettingsRow(
                            icon: "clock.fill",
                            iconColor: .blue,
                            title: LocalizationManager.shared.localized("학습 시간 목표"),
                            subtitle: LocalizationManager.shared.localized("하루 학습 시간 목표를 설정하세요")
                        ) {
                            Button(action: {
                                showGoalSettings.toggle()
                            }) {
                                Text(LocalizationManager.shared.localized("설정"))
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding()
        }
        .popover(isPresented: $showNotificationSettings) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showGoalSettings) {
            GoalSettingsView()
        }
    }
}

// 설정 섹션 컴포넌트
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 0) {
                content
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

// 설정 행 컴포넌트
struct SettingsRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let content: Content
    
    init(icon: String, iconColor: Color, title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            content
        }
    }
}

// 목표 설정 뷰
struct GoalSettingsView: View {
    @AppStorage("goalStudyHours") private var goalStudyHours: Int = 6
    @AppStorage("goalStudyMinutes") private var goalStudyMinutes: Int = 0
    @AppStorage("goalTodos") private var goalTodos: Int = 5
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // 헤더
            HStack {
                Text(LocalizationManager.shared.localized("목표 설정"))
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("닫기") {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            
            // 학습 시간 목표
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizationManager.shared.localized("학습 시간 목표"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationManager.shared.localized("시간"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Stepper("\(goalStudyHours)\(LocalizationManager.shared.localized("시"))", value: $goalStudyHours, in: 0...24)
                            .frame(width: 140)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationManager.shared.localized("분"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Stepper("\(goalStudyMinutes)\(LocalizationManager.shared.localized("분"))", value: $goalStudyMinutes, in: 0...59, step: 5)
                            .frame(width: 140)
                    }
                }
                
                // 프리셋 버튼들
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationManager.shared.localized("프리셋"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Button(LocalizationManager.shared.localized("4시간")) { 
                            goalStudyHours = 4; goalStudyMinutes = 0 
                        }
                        .buttonStyle(.bordered)
                        
                        Button(LocalizationManager.shared.localized("6시간")) { 
                            goalStudyHours = 6; goalStudyMinutes = 0 
                        }
                        .buttonStyle(.bordered)
                        
                        Button(LocalizationManager.shared.localized("8시간")) { 
                            goalStudyHours = 8; goalStudyMinutes = 0 
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            Divider()
            
            // 할 일 목표
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizationManager.shared.localized("할 일 목표"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationManager.shared.localized("할 일 개수"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Stepper("\(goalTodos)개", value: $goalTodos, in: 0...20)
                            .frame(width: 140)
                    }
                }
            }
            
            Spacer()
            
            // 기본값으로 복원 버튼
            HStack {
                Spacer()
                Button(LocalizationManager.shared.localized("기본값으로 복원")) {
                    goalStudyHours = 6
                    goalStudyMinutes = 0
                    goalTodos = 5
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    SettingsView(
        isDarkMode: .constant(false),
        autoEndOfDayEnabled: .constant(true),
        onRequestEndOfDay: {}
    )
}
