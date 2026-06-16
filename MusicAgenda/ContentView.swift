//
//  ContentView.swift
//  MusicAgenda
//
//  Created by Rohan Batra on 6/15/26.
//
import SwiftUI
import SwiftData

enum NavigationItem: Hashable {
    case inbox
    case inProgress
    case archive
    case search
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var albums: [Album]
    
    // This tracks what the user clicked in the sidebar
    @State private var selectedNav: NavigationItem? = .inbox

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedNav) {
                Section("Library") {
                    Label("Inbox / Queue", systemImage: "tray")
                        .tag(NavigationItem.inbox)
                    Label("In Progress", systemImage: "play.circle")
                        .tag(NavigationItem.inProgress)
                    Label("Archive", systemImage: "checkmark.circle")
                        .tag(NavigationItem.archive)
                }
                
                Section("Discover") {
                    Label("Search", systemImage: "magnifyingglass")
                        .tag(NavigationItem.search)
                }
            }
            .navigationTitle("Music Agenda")
            .listStyle(.sidebar)
        } detail: {
            // Depending on what is selected in the sidebar, show a different view!
            switch selectedNav {
            case .inbox:
                NavigationStack {
                    InboxView()
                }
            case .inProgress:
                Text("In Progress View")
                    .font(.largeTitle).foregroundStyle(.secondary)
            case .archive:
                Text("Archive View")
                    .font(.largeTitle).foregroundStyle(.secondary)
            case .search:
                NavigationStack {
                    SearchView()
                }
            case nil:
                Text("Select an item from the sidebar")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
