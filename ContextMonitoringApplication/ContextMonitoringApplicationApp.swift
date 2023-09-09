//
//  ContextMonitoringApplicationApp.swift
//  ContextMonitoringApplication
//
//  Created by Shawn Wang on 9/9/23.
//

import SwiftUI

@main
struct ContextMonitoringApplicationApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
