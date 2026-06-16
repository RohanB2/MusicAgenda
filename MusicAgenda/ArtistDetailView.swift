import SwiftUI

struct ArtistDetailView: View {
    let artistId: Int
    let artistName: String
    var onAlbumSelect: (ITunesResult) -> Void
    
    @State private var albums: [ITunesResult] = []
    @State private var isLoading = true
    
    let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text(artistName)
                    .font(.system(size: 60, weight: .heavy))
                    .padding(.horizontal)
                    .padding(.top, 40)
                
                Text("Albums")
                    .font(.title2.bold())
                    .padding(.horizontal)
                
                if isLoading {
                    ProgressView()
                        .padding(.top, 50)
                } else if albums.isEmpty {
                    Text("No albums found.")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(albums, id: \.collectionId) { result in
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    onAlbumSelect(result)
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
        }
        .task {
            await loadAlbums()
        }
    }
    
    private func loadAlbums() async {
        do {
            let fetched = try await ITunesAPI.shared.fetchAlbums(forArtistId: artistId)
            await MainActor.run {
                self.albums = fetched
                self.isLoading = false
            }
        } catch {
            print("Failed to load artist albums: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
}
