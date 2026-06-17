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
                        HStack(alignment: .top) {
                            Text(result.collectionName ?? "Unknown Album")
                                .font(.system(size: 32, weight: .bold))
                            if result.collectionExplicitness == "explicit" {
                                Image(systemName: "e.square.fill")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                            }
                        }
                        
                        HStack(alignment: .firstTextBaseline) {
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
                            
                            Text(formattedYear)
                                .font(.title3)
                                .foregroundStyle(.secondary.opacity(0.8))
                        }
                        
                        if !totalDurationString.isEmpty {
                            Text(totalDurationString)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
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
                                if track.trackExplicitness == "explicit" {
                                    Image(systemName: "e.square.fill")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                                Spacer()
                                
                                Button {
                                    if let albumId = result.collectionId, let trackId = track.trackId, let url = URL(string: "music://music.apple.com/album/id\(albumId)?i=\(trackId)") {
                                        NSWorkspace.shared.open(url)
                                    }
                                } label: {
                                    Image(systemName: "play.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, 8)
                                
                                Text(formattedTrackLength(millis: track.trackTimeMillis))
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal)
                            Divider()
                        }
                        
                        if let exactDate = formattedExactDate {
                            Text(exactDate)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.top, 20)
                                .padding(.bottom, 40) // Increased padding
                                .padding(.horizontal)
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
        
        let totalMillis = tracks.compactMap { $0.trackTimeMillis }.reduce(0, +)
        
        let newAlbum = Album(
            id: String(albumId),
            title: result.collectionName ?? "Unknown",
            artist: result.artistName ?? "Unknown",
            artistId: result.artistId,
            artworkUrlString: result.artworkUrl100,
            releaseDateString: result.releaseDate,
            totalTimeMillis: totalMillis > 0 ? totalMillis : nil,
            isExplicit: result.collectionExplicitness == "explicit"
        )
        
        for track in tracks {
            let newTrack = Track(
                id: String(track.trackId ?? UUID().hashValue),
                title: track.trackName ?? "Unknown",
                trackNumber: track.trackNumber ?? 0,
                trackTimeMillis: track.trackTimeMillis,
                isExplicit: track.trackExplicitness == "explicit"
            )
            newAlbum.tracks.append(newTrack)
        }
        
        // Save to Database
        modelContext.insert(newAlbum)
        isAdded = true
    }
    
    // Formatting Helpers
    private var formattedYear: String {
        guard let dateString = result.releaseDate else { return "" }
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let outFormatter = DateFormatter()
            outFormatter.dateFormat = "yyyy"
            return outFormatter.string(from: date)
        }
        return ""
    }
    
    private var formattedExactDate: String? {
        guard let dateString = result.releaseDate else { return nil }
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let outFormatter = DateFormatter()
            outFormatter.dateStyle = .long
            return outFormatter.string(from: date)
        }
        return nil
    }
    
    private var totalDurationString: String {
        let totalMillis = tracks.compactMap { $0.trackTimeMillis }.reduce(0, +)
        if totalMillis == 0 { return "" }
        let minutes = totalMillis / 60000
        return "\(minutes) mins"
    }
    
    private func formattedTrackLength(millis: Int?) -> String {
        guard let millis = millis, millis > 0 else { return "" }
        let totalSeconds = millis / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
