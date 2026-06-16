//
//  SavedAlbumDetailView.swift
//  MusicAgenda
//
//  Created by Rohan Batra on 6/16/26.
//

import SwiftUI
import SwiftData

struct SavedAlbumDetailView: View {
    let album: Album
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack(alignment: .bottom, spacing: 20) {
                    AsyncImage(url: ITunesAPI.shared.highResArtworkUrl(from: album.artworkUrlString)) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle().fill(Color.secondary.opacity(0.2))
                    }
                    .frame(width: 200, height: 200)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(album.title)
                            .font(.system(size: 32, weight: .bold))
                        Text(album.artist)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        // Progress Bar Logic!
                        let listenedCount = album.tracks.filter { $0.isListened }.count
                        let totalCount = album.tracks.count > 0 ? album.tracks.count : 1
                        let progress = Double(listenedCount) / Double(totalCount)
                        
                        ProgressView(value: progress)
                            .tint(.blue)
                            .padding(.top, 10)
                        
                        Text("\(listenedCount) of \(album.tracks.count) Listened")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                
                // Interactive Tracklist
                VStack(alignment: .leading) {
                    Text("Tracklist")
                        .font(.title2.bold())
                        .padding(.horizontal)
                    
                    let sortedTracks = album.tracks.sorted { $0.trackNumber < $1.trackNumber }
                    
                    ForEach(sortedTracks) { track in
                        HStack {
                            // Checkbox Button
                            Button {
                                track.isListened.toggle()
                            } label: {
                                Image(systemName: track.isListened ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(track.isListened ? .blue : .secondary)
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(track.trackNumber)")
                                .frame(width: 30, alignment: .trailing)
                                .foregroundStyle(.secondary)
                            
                            // Strikethrough the text if you already listened to it
                            Text(track.title)
                                .strikethrough(track.isListened, color: .secondary)
                                .foregroundStyle(track.isListened ? .secondary : .primary)
                            
                            Spacer()
                            
                            // Like Button
                            Button {
                                track.isLiked.toggle()
                            } label: {
                                Image(systemName: track.isLiked ? "heart.fill" : "heart")
                                    .foregroundStyle(track.isLiked ? .red : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal)
                        
                        Divider()
                    }
                }
            }
        }
    }
}
