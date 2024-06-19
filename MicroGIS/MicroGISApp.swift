//
//  MicroGISApp.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 7/4/24.
//

import SwiftUI

@main
struct MicroGISApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        #if os(macOS)
        .commands {
            SidebarCommands()
        }
        #endif
    }
}
