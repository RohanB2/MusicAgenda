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
    var onArtistSelect: ((Int, String) -> Void)?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showRatingSheet = false
    
    @State private var trackBeingEdited: Track? = nil
    @State private var editingNoteText: String = ""
    
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
                                        Image(systemName: star <= rating ? "star.fill" : "star")
                                            .font(.title3)
                                            .foregroundStyle(.yellow)
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
                            
                            // NEW DELETE BUTTON
                            Button(role: .destructive) {
                                modelContext.delete(album) // Delete from database
                                dismiss() // Close the view and go back
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
                                        let wasListened = track.isListened
                                        track.isListened.toggle()
                                        
                                        // If we just completed the album, show the rating sheet
                                        if !wasListened {
                                            let newListenedCount = album.tracks.filter { $0.isListened }.count
                                            if newListenedCount == album.tracks.count {
                                                showRatingSheet = true
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
                                
                                Text(formattedTrackLength(millis: track.trackTimeMillis))
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .padding(.trailing, 10)
                                
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
                                            track.note = nil
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
                        
                        if let exactDate = formattedExactDate {
                            Text(exactDate)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.top, 20)
                                .padding(.bottom, 40) // Increased padding
                                .padding(.horizontal, 20)
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
        .sheet(isPresented: $showRatingSheet) {
            RatingSheetView(album: album)
        }
        .alert("Track Note", isPresented: Binding(
            get: { trackBeingEdited != nil },
            set: { if !$0 { trackBeingEdited = nil } }
        )) {
            TextField("Add a note...", text: $editingNoteText)
            Button("Save") {
                if let track = trackBeingEdited {
                    withAnimation {
                        track.note = editingNoteText.isEmpty ? nil : editingNoteText
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
    private var formattedYear: String {
        guard let dateString = album.releaseDateString else { return "" }
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let outFormatter = DateFormatter()
            outFormatter.dateFormat = "yyyy"
            return outFormatter.string(from: date)
        }
        return ""
    }
    
    private var formattedExactDate: String? {
        guard let dateString = album.releaseDateString else { return nil }
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let outFormatter = DateFormatter()
            outFormatter.dateStyle = .long
            return outFormatter.string(from: date)
        }
        return nil
    }
    
    private var totalDurationString: String {
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
