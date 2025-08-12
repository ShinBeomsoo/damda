//
//  damda_devApp.swift
//  damda-dev
//
//  Created by SHIN BEOMSOO on 8/12/25.
//

import SwiftUI

@main
struct damda_devApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
