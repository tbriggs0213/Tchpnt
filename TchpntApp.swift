//
//  TchpntApp.swift
//  Tchpnt
//
//  Created by Tanner Briggs on 1/3/25.
//

import SwiftUI
import SwiftData

@main
struct TchpntApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Contact.self, // ✅ Updated: Ensure Contact model is included in SwiftData schema
        ])
        
        // Configure CloudKit integration
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.tannerbriggs.tchpnt")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer) // ✅ Ensures SwiftData is properly injected into ContentView
        }
    }
}
