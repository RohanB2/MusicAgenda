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

struct GenreCategory: Identifiable {
    let id = UUID()
    let title: String
    let colors: [Color]
}

let genericGenres: [GenreCategory] = [
    GenreCategory(title: "Pop", colors: [.pink, .red]),
    GenreCategory(title: "Hip-Hop", colors: [.blue, .cyan]),
    GenreCategory(title: "Alternative", colors: [.yellow, .orange]),
    GenreCategory(title: "Rock", colors: [.red, .orange]),
    GenreCategory(title: "R&B", colors: [.purple, .indigo]),
    GenreCategory(title: "Dance", colors: [.green, .mint]),
    GenreCategory(title: "Country", colors: [.orange, .yellow]),
    GenreCategory(title: "Jazz", colors: [.teal, .blue]),
    GenreCategory(title: "Classical", colors: [.gray, .black]),
    GenreCategory(title: "Electronic", colors: [.green, .black])
]

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var searchResults: [ITunesResult] = []
    @State private var isSearching = false
    
    @State private var path: [SearchPath] = []
    
    let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
    ]
    let categoryColumns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 20)
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
                    } else if searchText.isEmpty && searchResults.isEmpty {
                        // BROWSE CATEGORIES
                        VStack(alignment: .leading) {
                            Text("Browse Categories")
                                .font(.title.bold())
                                .padding(.horizontal)
                                .padding(.top, 20)
                            
                            LazyVGrid(columns: categoryColumns, spacing: 20) {
                                ForEach(genericGenres) { genre in
                                    Button {
                                        searchText = genre.title
                                        performSearch()
                                    } label: {
                                        ZStack(alignment: .bottomLeading) {
                                            LinearGradient(colors: genre.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                            
                                            Text(genre.title)
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundStyle(.white)
                                                .padding()
                                        }
                                        .frame(height: 120)
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                    } else {
                        // SEARCH RESULTS
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
        .navigationTitle(path.isEmpty ? "Home" : "")
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search Apple Music")
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
        .onChange(of: searchText) { oldValue, newValue in
            if newValue.isEmpty {
                withAnimation(.easeInOut(duration: 0.25)) {
                    searchResults.removeAll()
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        withAnimation(.easeInOut(duration: 0.25)) { path.removeAll() }
        
        Task {
            do {
                // Run artist search and album search in parallel
                async let artistResults = ITunesAPI.shared.searchArtists(query: searchText)
                async let albumResults = ITunesAPI.shared.searchAlbums(query: searchText)
                
                let (artists, albums) = try await (artistResults, albumResults)
                
                let query = searchText.lowercased()
                
                // Check if any returned artist is a strong match for what was typed
                var artistAlbums: [ITunesResult] = []
                if let matchedArtist = artists.first(where: { artist in
                    let name = (artist.artistName ?? "").lowercased()
                    // "Drake" contains "Drake", "Cry baby Vince Staples" contains "Vince Staples"
                    return query.contains(name) || name.contains(query)
                }), let artistId = matchedArtist.artistId {
                    // Fetch their full discography (sorted newest first)
                    artistAlbums = try await ITunesAPI.shared.fetchAlbums(forArtistId: artistId)
                }
                
                // Merge: artist discography first, then remaining album results (deduplicated)
                var seen = Set<Int>()
                var merged: [ITunesResult] = []
                
                for album in artistAlbums {
                    if let id = album.collectionId, !seen.contains(id) {
                        seen.insert(id)
                        merged.append(album)
                    }
                }
                
                for album in albums {
                    if let id = album.collectionId, !seen.contains(id) {
                        seen.insert(id)
                        merged.append(album)
                    }
                }
                
                await MainActor.run {
                    self.searchResults = merged
                    self.isSearching = false
                }
            } catch {
                print("Search failed: \(error)")
                await MainActor.run { self.isSearching = false }
            }
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
            
            HStack(spacing: 4) {
                Text(result.collectionName ?? "Unknown Album")
                    .font(.headline)
                    .lineLimit(1)
                
                if result.collectionExplicitness == "explicit" {
                    Image(systemName: "e.square.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                }
            }
            
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
