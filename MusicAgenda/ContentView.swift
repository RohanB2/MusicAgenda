//
//  ContentView.swift
//  MusicAgenda
//
//  Created by Rohan Batra on 6/15/26.
//

import SwiftUI
import SwiftData

enum NavigationItem: Hashable {
    case home
    case inbox
    case inProgress
    case archive
    case search
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var albums: [Album]
    
    @State private var selectedNav: NavigationItem? = .home // Default to Home now
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedNav) {
                Section("Discover") {
                    Label("Home", systemImage: "house.fill")
                        .tag(NavigationItem.home)
                    Label("Search", systemImage: "magnifyingglass")
                        .tag(NavigationItem.search)
                }
                
                Section("Library") {
                    Label("Inbox / Queue", systemImage: "tray.fill")
                        .tag(NavigationItem.inbox)
                    Label("In Progress", systemImage: "play.circle.fill")
                        .tag(NavigationItem.inProgress)
                    Label("Archive", systemImage: "archivebox.fill")
                        .tag(NavigationItem.archive)
                }
            }
            .navigationTitle("Music Agenda")
            .listStyle(.sidebar)
        } detail: {
            // A ZStack allows the old view to fade out while the new one fades in right on top of it!
            ZStack {
                switch selectedNav {
                case .home:
                    HomeView()
                        .transition(.opacity)
                case .inbox:
                    NavigationStack { LibraryView(filter: .inbox) }
                        .transition(.opacity)
                case .inProgress:
                    NavigationStack { LibraryView(filter: .inProgress) }
                        .transition(.opacity)
                case .archive:
                    NavigationStack { LibraryView(filter: .archive) }
                        .transition(.opacity)
                case .search:
                    NavigationStack { SearchView() }
                        .transition(.opacity)
                case nil:
                    Text("Select an item from the sidebar")
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }
            }
            // This tells the ZStack to animate any changes to selectedNav with a smooth 0.3s fade
            .animation(.easeInOut(duration: 0.3), value: selectedNav)
        }
    }
}
