//
//  MusicAgendaApp.swift
//  MusicAgenda
//
//  Created by Rohan Batra on 6/15/26.
//

import SwiftUI
import FirebaseCore

@main
struct MusicAgendaApp: App {
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup("Music Agenda") {
            RootView()
        }
    }
}
