//
//  LibraryView.swift
//  MusicAgenda
//
//  Created by Rohan Batra on 6/16/26.
//

import SwiftUI
import SwiftData

enum LibraryFilter {
    case inbox
    case inProgress
    case archive
}

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Album.dateAdded, order: .reverse) private var allAlbums: [Album]
    
    let filter: LibraryFilter
    

    @State private var selectedAlbum: Album?
    
    var filteredAlbums: [Album] {
        allAlbums.filter { album in
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
            if let album = selectedAlbum {
                // Show the detail view and fade it in
                SavedAlbumDetailView(album: album)
                    .transition(.opacity)
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
                                // NEW: A normal button that triggers our fade animation
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        selectedAlbum = album
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
        // Hide the title if we are looking at an album
        .navigationTitle(selectedAlbum != nil ? "" : navigationTitle)
        
        // NEW: Add a Back button to the top left toolbar if an album is open!
        .toolbar {
            if selectedAlbum != nil {
                // By removing .buttonStyle(.plain) and using .title3, it looks perfect!
                ToolbarItem(placement: .navigation) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { selectedAlbum = nil }
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
        case .inbox: return "Inbox / Queue"
        case .inProgress: return "In Progress"
        case .archive: return "Archive"
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
        case .inbox: return "Your Inbox is Empty"
        case .inProgress: return "No Albums in Progress"
        case .archive: return "You haven't finished any albums yet!"
        }
    }
}

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
