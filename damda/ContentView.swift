//
//  ContentView.swift
//  damda
//
//  Created by SHIN BEOMSOO on 8/6/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var timerManager = TimerManagerObservable(context: PersistenceController.shared.container.viewContext)
    @StateObject private var todoManager = TodoManagerObservable(context: PersistenceController.shared.container.viewContext)

    var body: some View {
        VStack(spacing: 32) {
            TimerView(timerManager: timerManager)
            Divider()
            TodoListView(todoManager: todoManager)
        }
        .padding()
    }
}
