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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // 1. The Premium Blurred Background
            GeometryReader { geometry in
                AsyncImage(url: ITunesAPI.shared.highResArtworkUrl(from: album.artworkUrlString)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        // Heavy blur creates the Apple Music feel
                        .blur(radius: 80)
                        .opacity(0.6)
                } placeholder: {
                    Color.clear
                }
            }
            .ignoresSafeArea()
            
            // 2. The Main Content
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    HStack(alignment: .bottom, spacing: 30) {
                        AsyncImage(url: ITunesAPI.shared.highResArtworkUrl(from: album.artworkUrlString)) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Rectangle().fill(Color.secondary.opacity(0.2))
                        }
                        .frame(width: 240, height: 240)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(album.title)
                                .font(.system(size: 40, weight: .heavy))
                            Text(album.artist)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.secondary)
                            
                            // NEW DELETE BUTTON
                            Button(role: .destructive) {
                                modelContext.delete(album) // Delete from database
                                dismiss() // Close the view and go back
                            } label: {
                                Label("Remove from Agenda", systemImage: "trash")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.red)
                            .padding(.top, 5)
                            
                            // Progress Bar Logic
                            let listenedCount = album.tracks.filter { $0.isListened }.count
                            let totalCount = album.tracks.count > 0 ? album.tracks.count : 1
                            let progress = Double(listenedCount) / Double(totalCount)
                            
                            ProgressView(value: progress)
                                .tint(.white) // Looks better on dark blurred backgrounds
                                .padding(.top, 15)
                            
                            Text("\(listenedCount) of \(album.tracks.count) Listened")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 40)
                    
                    // 3. Frosted Glass Tracklist
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Tracklist")
                            .font(.title2.bold())
                            .padding()
                        
                        Divider()
                        
                        let sortedTracks = album.tracks.sorted { $0.trackNumber < $1.trackNumber }
                        
                        ForEach(sortedTracks) { track in
                            HStack {
                                // Animated Checkbox Button
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        track.isListened.toggle()
                                    }
                                } label: {
                                    Image(systemName: track.isListened ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(track.isListened ? .blue : .primary)
                                        .font(.title2)
                                        .scaleEffect(track.isListened ? 1.1 : 1.0)
                                }
                                .buttonStyle(.plain)
                                
                                Text("\(track.trackNumber)")
                                    .frame(width: 30, alignment: .trailing)
                                    .foregroundStyle(.secondary)
                                
                                Text(track.title)
                                    .strikethrough(track.isListened, color: .secondary)
                                    .foregroundStyle(track.isListened ? .secondary : .primary)
                                    .font(.system(size: 16, weight: .medium))
                                
                                Spacer()
                                
                                // Animated Like Button
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                        track.isLiked.toggle()
                                    }
                                } label: {
                                    Image(systemName: track.isLiked ? "heart.fill" : "heart")
                                        .foregroundStyle(track.isLiked ? .red : .secondary)
                                        .scaleEffect(track.isLiked ? 1.2 : 1.0)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            // Highlight the background if we hover
                            .background(HoverBackground())
                            
                            if track.id != sortedTracks.last?.id {
                                Divider().padding(.leading, 60)
                            }
                        }
                    }
                    // This is the magic macOS frosted glass material!
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// Helper view to create a nice hover effect on track rows
struct HoverBackground: View {
    @State private var isHovered = false
    var body: some View {
        Rectangle()
            .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
    }
}
