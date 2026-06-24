import SwiftUI

struct RatingSheetView: View {
    let albumId: String
    @Environment(FirestoreManager.self) private var firestoreManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var expandedTracks: Set<String> = []
    
    var album: FirebaseAlbum? {
        firestoreManager.albums.first(where: { $0.id == albumId })
    }
    
    var body: some View {
        NavigationStack {
            if let album = album {
                Form {
                    Section {
                        VStack(spacing: 20) {
                            if let urlString = album.artworkUrlString, let url = URL(string: urlString.replacingOccurrences(of: "100x100bb", with: "300x300bb")) {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                         .aspectRatio(contentMode: .fit)
                                         .frame(width: 150, height: 150)
                                         .cornerRadius(12)
                                         .shadow(radius: 5)
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                        .frame(width: 150, height: 150)
                                        .cornerRadius(12)
                                }
                            }
                            
                            VStack(spacing: 4) {
                                Text(album.title)
                                    .font(.title2.bold())
                                    .multilineTextAlignment(.center)
                                
                                Text(album.artist)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // 5 Star Rating
                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= (album.rating ?? 0) ? "star.fill" : "star")
                                        .font(.system(size: 30))
                                        .foregroundStyle(star <= (album.rating ?? 0) ? .yellow : .gray.opacity(0.4))
                                        .onTapGesture {
                                            withAnimation {
                                                var updatedAlbum = album
                                                updatedAlbum.rating = star
                                                firestoreManager.addAlbum(updatedAlbum)
                                            }
                                        }
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }
                    
                    Section("Track Notes") {
                        let sortedTracks = album.tracks.sorted { $0.trackNumber < $1.trackNumber }
                        ForEach(sortedTracks) { track in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("\(track.trackNumber). \(track.title)")
                                        .font(.headline)
                                    Spacer()
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if expandedTracks.contains(track.id) {
                                                expandedTracks.remove(track.id)
                                            } else {
                                                expandedTracks.insert(track.id)
                                            }
                                        }
                                    } label: {
                                        Image(systemName: expandedTracks.contains(track.id) ? "text.bubble.fill" : "text.bubble")
                                            .foregroundStyle(expandedTracks.contains(track.id) ? .blue : .secondary)
                                            .font(.system(size: 16))
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                if expandedTracks.contains(track.id) {
                                    TextField("Add a note...", text: Binding(
                                        get: { track.note ?? "" },
                                        set: { newValue in
                                            var updatedAlbum = album
                                            if let index = updatedAlbum.tracks.firstIndex(where: { $0.id == track.id }) {
                                                updatedAlbum.tracks[index].note = newValue.isEmpty ? nil : newValue
                                                firestoreManager.addAlbum(updatedAlbum)
                                            }
                                        }
                                    ), axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(1...5)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
                .formStyle(.grouped)
                .navigationTitle("Rate & Review")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .onAppear {
                    for track in album.tracks {
                        if let note = track.note, !note.isEmpty {
                            expandedTracks.insert(track.id)
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
}
