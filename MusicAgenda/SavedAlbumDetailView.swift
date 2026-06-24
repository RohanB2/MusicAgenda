//
//  SavedAlbumDetailView.swift
//  MusicAgenda
//
//  Created by Rohan Batra on 6/16/26.
//

import SwiftUI

struct SavedAlbumDetailView: View {
    let albumId: String
    var onArtistSelect: ((Int, String) -> Void)?
    @Environment(FirestoreManager.self) private var firestoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var showRatingSheet = false
    
    @State private var trackBeingEdited: FirebaseTrack? = nil
    @State private var editingNoteText: String = ""
    
    var album: FirebaseAlbum? {
        firestoreManager.albums.first(where: { $0.id == albumId })
    }
    
    var body: some View {
        Group {
            if let album = album {
                albumContent(album)
            } else {
                ProgressView()
            }
        }
    }
    
    @ViewBuilder
    private func albumContent(_ album: FirebaseAlbum) -> some View {
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
                            HStack(alignment: .top) {
                                Text(album.title)
                                    .font(.system(size: 40, weight: .heavy))
                                if album.isExplicit {
                                    Image(systemName: "e.square.fill")
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 12)
                                }
                            }
                            
                            if let rating = album.rating {
                                HStack(spacing: 4) {
                                    ForEach(1...5, id: \.self) { star in
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                var updatedAlbum = album
                                                updatedAlbum.rating = star
                                                firestoreManager.addAlbum(updatedAlbum)
                                            }
                                        } label: {
                                            Image(systemName: star <= rating ? "star.fill" : "star")
                                                .font(.title3)
                                                .foregroundStyle(.yellow)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            } else if album.tracks.count > 0 && album.tracks.filter({ $0.isListened }).count == album.tracks.count {
                                // Album is complete but no rating yet
                                HStack(spacing: 4) {
                                    ForEach(1...5, id: \.self) { star in
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                var updatedAlbum = album
                                                updatedAlbum.rating = star
                                                firestoreManager.addAlbum(updatedAlbum)
                                            }
                                        } label: {
                                            Image(systemName: "star")
                                                .font(.title3)
                                                .foregroundStyle(.yellow.opacity(0.4))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            HStack(alignment: .firstTextBaseline) {
                                if let artistId = album.artistId {
                                    Button {
                                        onArtistSelect?(artistId, album.artist)
                                    } label: {
                                        Text(album.artist)
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Text(album.artist)
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                                
                                Text(formattedYear(for: album))
                                    .font(.title3)
                                    .foregroundStyle(.secondary.opacity(0.8))
                            }
                            
                            if !totalDurationString(for: album).isEmpty {
                                Text(totalDurationString(for: album))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 2)
                            }
                            
                            // DELETE BUTTON
                            Button(role: .destructive) {
                                firestoreManager.deleteAlbum(album)
                                dismiss()
                            } label: {
                                Label("Remove from Agenda", systemImage: "trash")
                                    .font(.subheadline.bold())
                                }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .padding(.top, 5)
                            
                            // Progress Bar Logic
                            let listenedCount = album.tracks.filter { $0.isListened }.count
                            let totalCount = album.tracks.count > 0 ? album.tracks.count : 1
                            let progress = Double(listenedCount) / Double(totalCount)
                            
                            ProgressView(value: progress)
                                .tint(.white)
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
                                        var updatedAlbum = album
                                        if let index = updatedAlbum.tracks.firstIndex(where: { $0.id == track.id }) {
                                            let wasListened = updatedAlbum.tracks[index].isListened
                                            updatedAlbum.tracks[index].isListened.toggle()
                                            firestoreManager.addAlbum(updatedAlbum)
                                            
                                            if !wasListened {
                                                let newListenedCount = updatedAlbum.tracks.filter { $0.isListened }.count
                                                if newListenedCount == updatedAlbum.tracks.count {
                                                    showRatingSheet = true
                                                }
                                            }
                                        }
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
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(track.title)
                                        .strikethrough(track.isListened, color: .secondary)
                                        .foregroundStyle(track.isListened ? .secondary : .primary)
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    if let note = track.note, !note.isEmpty {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .italic()
                                            .padding(.leading, 8)
                                            .overlay(
                                                Rectangle()
                                                    .fill(Color.secondary.opacity(0.3))
                                                    .frame(width: 2),
                                                alignment: .leading
                                            )
                                    }
                                }
                                
                                if track.isExplicit {
                                    Image(systemName: "e.square.fill")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                                
                                Spacer()
                                
                                Button {
                                    if let url = URL(string: "music://music.apple.com/album/id\(album.id)?i=\(track.id)") {
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
                                    .padding(.trailing, 10)
                                
                                // Animated Like Button
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                        var updatedAlbum = album
                                        if let index = updatedAlbum.tracks.firstIndex(where: { $0.id == track.id }) {
                                            updatedAlbum.tracks[index].isLiked.toggle()
                                            firestoreManager.addAlbum(updatedAlbum)
                                        }
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
                            .background(HoverBackground())
                            .contextMenu {
                                if let note = track.note, !note.isEmpty {
                                    Button {
                                        editingNoteText = note
                                        trackBeingEdited = track
                                    } label: {
                                        Label("Edit Note", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        withAnimation {
                                            var updatedAlbum = album
                                            if let index = updatedAlbum.tracks.firstIndex(where: { $0.id == track.id }) {
                                                updatedAlbum.tracks[index].note = nil
                                                firestoreManager.addAlbum(updatedAlbum)
                                            }
                                        }
                                    } label: {
                                        Label("Clear Note", systemImage: "trash")
                                    }
                                } else {
                                    Button {
                                        editingNoteText = ""
                                        trackBeingEdited = track
                                    } label: {
                                        Label("Add Note", systemImage: "text.bubble")
                                    }
                                }
                            }
                            
                            if track.id != sortedTracks.last?.id {
                                Divider().padding(.leading, 60)
                            }
                        }
                        
                        if let exactDate = formattedExactDate(for: album) {
                            Text(exactDate)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.top, 20)
                                .padding(.bottom, 40)
                                .padding(.horizontal, 20)
                        }
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showRatingSheet) {
            RatingSheetView(albumId: album.id)
        }
        .alert("Track Note", isPresented: Binding(
            get: { trackBeingEdited != nil },
            set: { if !$0 { trackBeingEdited = nil } }
        )) {
            TextField("Add a note...", text: $editingNoteText)
            Button("Save") {
                if let track = trackBeingEdited {
                    withAnimation {
                        var updatedAlbum = album
                        if let index = updatedAlbum.tracks.firstIndex(where: { $0.id == track.id }) {
                            updatedAlbum.tracks[index].note = editingNoteText.isEmpty ? nil : editingNoteText
                            firestoreManager.addAlbum(updatedAlbum)
                        }
                    }
                }
                trackBeingEdited = nil
            }
            Button("Cancel", role: .cancel) {
                trackBeingEdited = nil
            }
        }
    }
    
    // Formatting Helpers
    private func formattedYear(for album: FirebaseAlbum) -> String {
        guard let dateString = album.releaseDateString else { return "" }
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let outFormatter = DateFormatter()
            outFormatter.dateFormat = "yyyy"
            return outFormatter.string(from: date)
        }
        return ""
    }
    
    private func formattedExactDate(for album: FirebaseAlbum) -> String? {
        guard let dateString = album.releaseDateString else { return nil }
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let outFormatter = DateFormatter()
            outFormatter.dateStyle = .long
            return outFormatter.string(from: date)
        }
        return nil
    }
    
    private func totalDurationString(for album: FirebaseAlbum) -> String {
        guard let totalMillis = album.totalTimeMillis else { return "" }
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
