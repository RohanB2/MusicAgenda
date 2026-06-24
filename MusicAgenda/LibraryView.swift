import SwiftUI

enum LibraryFilter {
    case inbox
    case inProgress
    case archive
}

enum LibraryPath: Equatable {
    case savedAlbum(String)
    case artist(Int, String) // artistId, artistName
    case searchAlbum(ITunesResult)
    
    static func == (lhs: LibraryPath, rhs: LibraryPath) -> Bool {
        switch (lhs, rhs) {
        case (.savedAlbum(let l), .savedAlbum(let r)): return l == r
        case (.artist(let lId, _), .artist(let rId, _)): return lId == rId
        case (.searchAlbum(let l), .searchAlbum(let r)): return l.collectionId == r.collectionId
        default: return false
        }
    }
}

struct LibraryView: View {
    @Environment(FirestoreManager.self) private var firestoreManager
    private var allAlbums: [FirebaseAlbum] { firestoreManager.albums }
    
    let filter: LibraryFilter
    @State private var searchText = ""
    
    @State private var path: [LibraryPath] = []
    
    var filteredAlbums: [FirebaseAlbum] {
        let textFiltered = searchText.isEmpty ? allAlbums : allAlbums.filter { album in
            album.title.localizedCaseInsensitiveContains(searchText) ||
            album.artist.localizedCaseInsensitiveContains(searchText)
        }
        
        return textFiltered.filter { album in
            let listenedCount = album.tracks.filter { $0.isListened }.count
            let totalCount = album.tracks.count > 0 ? album.tracks.count : 1
            switch filter {
            case .inbox: return listenedCount == 0
            case .inProgress: return listenedCount > 0 && listenedCount < totalCount
            case .archive: return listenedCount == totalCount
            }
        }
    }
    
    let columns = [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)]

    var body: some View {
        ZStack {
            if let current = path.last {
                switch current {
                case .savedAlbum(let albumId):
                    SavedAlbumDetailView(albumId: albumId) { artistId, artistName in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            path.append(.artist(artistId, artistName))
                        }
                    }
                    .transition(.opacity)
                case .artist(let artistId, let artistName):
                    ArtistDetailView(artistId: artistId, artistName: artistName) { albumResult in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            path.append(.searchAlbum(albumResult))
                        }
                    }
                    .transition(.opacity)
                case .searchAlbum(let result):
                    SearchAlbumDetailView(result: result) { artistId, artistName in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            path.append(.artist(artistId, artistName))
                        }
                    }
                    .transition(.opacity)
                }
            } else {
                // Show the Grid and fade it in
                ScrollView {
                    if filteredAlbums.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: emptyStateIcon)
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary.opacity(0.5))
                            Text(emptyStateMessage)
                                .font(.title2.bold())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 150)
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(filteredAlbums) { album in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        path.append(.savedAlbum(album.id))
                                    }
                                } label: {
                                    SavedAlbumCardView(album: album)
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
        .navigationTitle(path.isEmpty ? navigationTitle : "")
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search Library")
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
    }
    
    private var navigationTitle: String {
        switch filter {
        case .inbox: return "Agenda"
        case .inProgress: return "In Progress"
        case .archive: return "Completed"
        }
    }
    private var emptyStateIcon: String {
        switch filter {
        case .inbox: return "tray.fill"
        case .inProgress: return "play.circle.fill"
        case .archive: return "archivebox.fill"
        }
    }
    private var emptyStateMessage: String {
        switch filter {
        case .inbox: return "Your Agenda is Empty"
        case .inProgress: return "No Albums in Progress"
        case .archive: return "You haven't finished any albums yet!"
        }
    }
}

struct SavedAlbumCardView: View {
    let album: FirebaseAlbum
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: ITunesAPI.shared.highResArtworkUrl(from: album.artworkUrlString)) { image in
                image.resizable().aspectRatio(1.0, contentMode: .fit)
            } placeholder: {
                Rectangle().fill(Color.secondary.opacity(0.2)).aspectRatio(1.0, contentMode: .fit)
            }
            .cornerRadius(12)
            .shadow(color: .black.opacity(isHovering ? 0.3 : 0.1), radius: isHovering ? 10 : 5, y: isHovering ? 5 : 2)
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
            
            if let rating = album.rating {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 2)
            }
            
            HStack(spacing: 4) {
                Text(album.title)
                    .font(.headline)
                    .lineLimit(1)
                
                if album.isExplicit {
                    Image(systemName: "e.square.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                }
            }
            
            Text(album.artist)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
