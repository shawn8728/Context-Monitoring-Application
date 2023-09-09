//
//  ContextMonitoringApplicationApp.swift
//  ContextMonitoringApplication
//
//  Created by Shawn Wang on 9/6/23.
//

import SwiftUI

@main
struct ContextMonitoringApplicationApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
