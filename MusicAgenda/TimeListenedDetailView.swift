import SwiftUI
import SwiftData

struct TimeListenedDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var albums: [Album]
    
    // We get all listened tracks, paired with their album for context
    private var listenedTracks: [(track: Track, album: Album)] {
        var results: [(track: Track, album: Album)] = []
        for album in albums {
            for track in album.tracks where track.isListened {
                results.append((track: track, album: album))
            }
        }
        // Sort by longest duration first
        return results.sorted { (a: (track: Track, album: Album), b: (track: Track, album: Album)) -> Bool in
            return (a.track.trackTimeMillis ?? 0) > (b.track.trackTimeMillis ?? 0)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if listenedTracks.isEmpty {
                    Text("No listened tracks yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(listenedTracks, id: \.track.id) { item in
                        HStack(spacing: 12) {
                            if let artUrl = item.album.artworkUrlString, let url = URL(string: artUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        Color.gray.opacity(0.3)
                                    case .success(let image):
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    case .failure:
                                        Color.gray.opacity(0.3)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(width: 40, height: 40)
                                .cornerRadius(4)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(item.track.title)
                                    .font(.headline)
                                Text(item.album.artist)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(formattedTrackLength(millis: item.track.trackTimeMillis ?? 0))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Time Listened Breakdown")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .frame(minWidth: 500, minHeight: 400)
        }
    }
    
    private func formattedTrackLength(millis: Int) -> String {
        let totalSeconds = millis / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
