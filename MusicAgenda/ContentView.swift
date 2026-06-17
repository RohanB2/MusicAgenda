import SwiftUI
import SwiftData

enum NavigationItem: Hashable {
    case home
    case search
    case inbox
    case inProgress
    case archive
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var albums: [Album]
    
    @State private var selectedNav: NavigationItem? = .home
    
    private var inboxCount: Int {
        albums.filter { album in
            let listenedCount = album.tracks.filter { $0.isListened }.count
            return listenedCount == 0
        }.count
    }
    
    private var inProgressCount: Int {
        albums.filter { album in
            let listenedCount = album.tracks.filter { $0.isListened }.count
            let totalCount = album.tracks.count > 0 ? album.tracks.count : 1
            return listenedCount > 0 && listenedCount < totalCount
        }.count
    }
    
    private var archiveCount: Int {
        albums.filter { album in
            let listenedCount = album.tracks.filter { $0.isListened }.count
            let totalCount = album.tracks.count > 0 ? album.tracks.count : 1
            return listenedCount == totalCount
        }.count
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedNav) {
                Section("Discover") {
                    Label("Dashboard", systemImage: "house.fill")
                        .tag(NavigationItem.home)
                    Label("Search", systemImage: "magnifyingglass")
                        .tag(NavigationItem.search)
                }
                
                Section("Library") {
                    Label("Agenda", systemImage: "tray.fill")
                        .badge(inboxCount)
                        .tag(NavigationItem.inbox)
                    Label("In Progress", systemImage: "play.circle.fill")
                        .badge(inProgressCount)
                        .tag(NavigationItem.inProgress)
                    Label("Completed", systemImage: "archivebox.fill")
                        .badge(archiveCount)
                        .tag(NavigationItem.archive)
                }
            }
            .navigationTitle("Music Agenda")
            .listStyle(.sidebar)
        } detail: {
            ZStack {
                switch selectedNav {
                case .home:
                    HomeDashboardView(selectedNav: $selectedNav)
                        .transition(.opacity)
                case .search:
                    SearchView()
                        .transition(.opacity)
                case .inbox:
                    LibraryView(filter: .inbox)
                        .transition(.opacity)
                case .inProgress:
                    LibraryView(filter: .inProgress)
                        .transition(.opacity)
                case .archive:
                    LibraryView(filter: .archive)
                        .transition(.opacity)
                case nil:
                    LibraryView(filter: .inbox)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedNav)
        }
    }
}
