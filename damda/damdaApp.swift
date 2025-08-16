//
//  damdaApp.swift
//  damda
//
//  Created by SHIN BEOMSOO on 8/6/25.
//

import SwiftUI
import UserNotifications

@main
struct damdaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // 알림 카테고리 설정
        NotificationManager.shared.setupNotificationCategories()
        
        // 알림 권한 요청
        NotificationManager.shared.requestNotificationPermission()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.actionIdentifier == "REVIEW_ACTION" {
            // 복습 화면으로 이동하는 로직
            // ContentView에서 처리할 수 있도록 NotificationCenter를 통해 메시지 전달
            NotificationCenter.default.post(name: .showReviewScreen, object: nil)
        }
        
        completionHandler()
    }
}

extension Notification.Name {
    static let showReviewScreen = Notification.Name("showReviewScreen")
}
