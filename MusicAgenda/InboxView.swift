//
//  InboxView.swift
//  MusicAgenda
//
//  Created by Rohan Batra on 6/16/26.
//

import SwiftUI
import SwiftData

struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    // This fetches all albums saved in SwiftData, sorted by the date you added them!
    @Query(sort: \Album.dateAdded, order: .reverse) private var albums: [Album]
    
    let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
    ]

    var body: some View {
        ScrollView {
            if albums.isEmpty {
                VStack {
                    Text("Your Agenda is Empty")
                        .font(.title2.bold())
                    Text("Go to the Search tab to find some new music!")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 100)
            } else {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(albums) { album in
                        NavigationLink(destination: SavedAlbumDetailView(album: album)) {
                            SavedAlbumCardView(album: album)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Inbox / Queue")
    }
}

// A slightly modified card that uses our local Album model instead of the API Result
struct SavedAlbumCardView: View {
    let album: Album
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
            
            Text(album.title)
                .font(.headline)
                .lineLimit(1)
            
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
