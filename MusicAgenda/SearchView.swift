//
//  SearchView.swift
//  MusicAgenda
//
//  Created by Rohan Batra on 6/15/26.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var searchResults: [ITunesResult] = []
    @State private var isSearching = false
    
    // A flexible grid layout for macOS
    let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
    ]

    var body: some View {
        ScrollView {
            if isSearching {
                ProgressView()
                    .padding(.top, 50)
            } else if searchResults.isEmpty && !searchText.isEmpty {
                Text("No results found.")
                    .foregroundStyle(.secondary)
                    .padding(.top, 50)
            } else {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(searchResults, id: \.collectionId) { result in
                        NavigationLink(destination: SearchAlbumDetailView(result: result)) {
                            AlbumCardView(result: result)
                        }
                        .buttonStyle(.plain) // This keeps our nice hover animations intact!
                    }
                }
            }
        }
        .navigationTitle("Search Albums")
        // This adds the native search bar in the top right corner!
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search by album or artist")
        .onSubmit(of: .search) {
            performSearch()
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        
        Task {
            do {
                let results = try await ITunesAPI.shared.searchAlbums(query: searchText)
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                print("Search failed: \(error)")
                await MainActor.run { self.isSearching = false }
            }
        }
    }
}

// A beautiful card to display each search result
struct AlbumCardView: View {
    let result: ITunesResult
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading) {
            // Artwork Image loading directly from the URL
            AsyncImage(url: ITunesAPI.shared.highResArtworkUrl(from: result.artworkUrl100)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fit)
                case .failure:
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(Image(systemName: "music.note").foregroundStyle(.secondary))
                @unknown default:
                    EmptyView()
                }
            }
            .cornerRadius(12)
            // A subtle shadow and scale effect when you hover your mouse over it!
            .shadow(color: .black.opacity(isHovering ? 0.3 : 0.1), radius: isHovering ? 10 : 5, y: isHovering ? 5 : 2)
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
            
            Text(result.collectionName ?? "Unknown Album")
                .font(.headline)
                .lineLimit(1)
            
            Text(result.artistName ?? "Unknown Artist")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
