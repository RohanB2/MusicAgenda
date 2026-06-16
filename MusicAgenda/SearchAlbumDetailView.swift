//
//  SearchAlbumDetailView.swift
//  MusicAgenda
//
//  Created by Rohan Batra on 6/15/26.
//

import SwiftUI
import SwiftData

struct SearchAlbumDetailView: View {
    @Environment(\.modelContext) private var modelContext
    
    let result: ITunesResult
    var onArtistSelect: ((Int, String) -> Void)?
    @State private var tracks: [ITunesResult] = []
    @State private var isLoading = true
    @State private var isAdded = false
    
    // Check if album is already in our database
    @Query private var savedAlbums: [Album]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header (Artwork + Info)
                HStack(alignment: .bottom, spacing: 20) {
                    AsyncImage(url: ITunesAPI.shared.highResArtworkUrl(from: result.artworkUrl100)) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle().fill(Color.secondary.opacity(0.2))
                    }
                    .frame(width: 200, height: 200)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(result.collectionName ?? "Unknown Album")
                            .font(.system(size: 32, weight: .bold))
                        if let artistId = result.artistId, let artistName = result.artistName {
                            Button {
                                onArtistSelect?(artistId, artistName)
                            } label: {
                                Text(artistName)
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text(result.artistName ?? "Unknown Artist")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button(action: addToAgenda) {
                            Label(isAdded ? "Added to Agenda" : "Add to Agenda", systemImage: isAdded ? "checkmark" : "plus")
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isAdded)
                        .padding(.top, 10)
                    }
                    Spacer()
                }
                .padding()
                
                // Tracklist
                if isLoading {
                    ProgressView()
                } else {
                    VStack(alignment: .leading) {
                        Text("Tracklist")
                            .font(.title2.bold())
                            .padding(.horizontal)
                        
                        ForEach(tracks, id: \.trackId) { track in
                            HStack {
                                Text("\(track.trackNumber ?? 0)")
                                    .frame(width: 30, alignment: .trailing)
                                    .foregroundStyle(.secondary)
                                Text(track.trackName ?? "Unknown Track")
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal)
                            Divider()
                        }
                    }
                }
            }
        }
        .task {
            await loadTracks()
            checkIfAlreadyAdded()
        }
    }
    
    private func loadTracks() async {
        guard let albumId = result.collectionId else { return }
        do {
            let fetched = try await ITunesAPI.shared.fetchTracks(forAlbumId: albumId)
            await MainActor.run {
                self.tracks = fetched.sorted { ($0.trackNumber ?? 0) < ($1.trackNumber ?? 0) }
                self.isLoading = false
            }
        } catch {
            print("Failed to load tracks: \(error)")
        }
    }
    
    private func checkIfAlreadyAdded() {
        if let id = result.collectionId {
            isAdded = savedAlbums.contains { $0.id == String(id) }
        }
    }
    
    private func addToAgenda() {
        guard let albumId = result.collectionId else { return }
        
        let newAlbum = Album(
            id: String(albumId),
            title: result.collectionName ?? "Unknown",
            artist: result.artistName ?? "Unknown",
            artworkUrlString: result.artworkUrl100
        )
        
        // Convert API tracks into SwiftData Tracks
        for trackResult in tracks {
            guard let trackId = trackResult.trackId else { continue }
            let newTrack = Track(
                id: String(trackId),
                title: trackResult.trackName ?? "Unknown",
                trackNumber: trackResult.trackNumber ?? 0
            )
            newAlbum.tracks.append(newTrack)
        }
        
        // Save to Database
        modelContext.insert(newAlbum)
        isAdded = true
    }
}
