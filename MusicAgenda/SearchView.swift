import SwiftUI
import SwiftData

enum SearchPath: Equatable {
    case album(ITunesResult)
    case artist(Int, String) // artistId, artistName
    
    static func == (lhs: SearchPath, rhs: SearchPath) -> Bool {
        switch (lhs, rhs) {
        case (.album(let l), .album(let r)): return l.collectionId == r.collectionId
        case (.artist(let lId, _), .artist(let rId, _)): return lId == rId
        default: return false
        }
    }
}

extension ITunesResult: Equatable {
    public static func == (lhs: ITunesResult, rhs: ITunesResult) -> Bool {
        return lhs.collectionId == rhs.collectionId && lhs.trackId == rhs.trackId
    }
}

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var searchResults: [ITunesResult] = []
    @State private var isSearching = false
    
    @State private var path: [SearchPath] = []
    
    let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
    ]

    var body: some View {
        ZStack {
            if let current = path.last {
                switch current {
                case .album(let result):
                    SearchAlbumDetailView(result: result) { artistId, artistName in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            path.append(.artist(artistId, artistName))
                        }
                    }
                    .transition(.opacity)
                case .artist(let artistId, let artistName):
                    ArtistDetailView(artistId: artistId, artistName: artistName) { albumResult in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            path.append(.album(albumResult))
                        }
                    }
                    .transition(.opacity)
                }
            } else {
                // The Grid
                ScrollView {
                    if isSearching {
                        ProgressView()
                            .padding(.top, 50)
                    } else if searchResults.isEmpty && !searchText.isEmpty {
                        Text("No results found.")
                            .foregroundStyle(.secondary)
                            .padding(.top, 50)
                    } else {
                        if searchText.isEmpty && !searchResults.isEmpty {
                            HStack {
                                Text("New Releases")
                                    .font(.title.bold())
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(searchResults, id: \.collectionId) { result in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        path.append(.album(result))
                                    }
                                } label: {
                                    AlbumCardView(result: result)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
                .transition(.opacity)
            }
        }
        .navigationTitle(path.isEmpty ? "Search Albums" : "")
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search by album or artist")
        .onSubmit(of: .search) {
            performSearch()
        }
        .toolbar {
            if !path.isEmpty {
                ToolbarItem(placement: .navigation) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            _ = path.removeLast()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                    }
                }
            }
        }
        .task {
            if searchResults.isEmpty && searchText.isEmpty {
                await loadRecentReleases()
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        withAnimation(.easeInOut(duration: 0.25)) { path.removeAll() } // Pop back to grid
        
        Task {
            do {
                let results = try await ITunesAPI.shared.searchAlbums(query: searchText)
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                print("Search failed: \(error)")
                await MainActor.run { self.isSearching = false }
            }
        }
    }
    
    private func loadRecentReleases() async {
        isSearching = true
        do {
            let results = try await ITunesAPI.shared.fetchRecentReleases()
            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
            }
        } catch {
            print("Failed to load recent releases: \(error)")
            await MainActor.run { self.isSearching = false }
        }
    }
}

// A beautiful card to display each search result
struct AlbumCardView: View {
    let result: ITunesResult
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: ITunesAPI.shared.highResArtworkUrl(from: result.artworkUrl100)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fit)
                case .failure:
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(Image(systemName: "music.note").foregroundStyle(.secondary))
                @unknown default:
                    EmptyView()
                }
            }
            .cornerRadius(12)
            .shadow(color: .black.opacity(isHovering ? 0.3 : 0.1), radius: isHovering ? 10 : 5, y: isHovering ? 5 : 2)
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
            
            Text(result.collectionName ?? "Unknown Album")
                .font(.headline)
                .lineLimit(1)
            
            Text(result.artistName ?? "Unknown Artist")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
