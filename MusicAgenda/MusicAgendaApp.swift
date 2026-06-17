//
//  MusicAgendaApp.swift
//  MusicAgenda
//
//  Created by Rohan Batra on 6/15/26.
//

import SwiftUI
import SwiftData

@main
struct MusicAgendaApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Album.self, Track.self
        ])
        let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.rohanbatra.MusicAgenda")!.appendingPathComponent("MusicAgenda.sqlite")
        let modelConfiguration = ModelConfiguration(schema: schema, url: sharedURL)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup("Music Agenda") {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
