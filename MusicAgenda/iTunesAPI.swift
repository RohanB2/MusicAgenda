//
//  iTunesAPI.swift
//  MusicAgenda
//
//  Created by Rohan Batra on 6/15/26.
//

import Foundation

struct ITunesSearchResponse: Codable {
    let results: [ITunesResult]
}

struct ITunesResult: Codable {
    let wrapperType: String?
    let collectionType: String?
    
    let collectionId: Int?
    let collectionName: String?
    let artistId: Int?
    let artistName: String?
    let artworkUrl100: String?
    let releaseDate: String?
    
    let trackId: Int?
    let trackName: String?
    let trackNumber: Int?
}

@Observable
class ITunesAPI {
    static let shared = ITunesAPI()
    // 1. Search for Albums (Smart Search)
    func searchAlbums(query: String) async throws -> [ITunesResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              // Changed 'entity=album' to 'media=music' so it searches songs too!
              let url = URL(string: "https://itunes.apple.com/search?term=\(encodedQuery)&media=music&limit=50") else {
            return []
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
        
        // Because a song search returns multiple songs from the same album,
        // we use a Dictionary to ensure we only show each unique album once.
        var uniqueAlbums: [Int: ITunesResult] = [:]
        for result in response.results {
            if let collectionId = result.collectionId {
                if uniqueAlbums[collectionId] == nil {
                    uniqueAlbums[collectionId] = result
                }
            }
        }
        
        // Sort by release date (newest first)
        let sortedAlbums = uniqueAlbums.values.sorted { result1, result2 in
            let date1 = result1.releaseDate ?? ""
            let date2 = result2.releaseDate ?? ""
            return date1 > date2 // Descending order
        }
        
        return sortedAlbums
    }
    
    // 2. Fetch tracks for a specific album
    func fetchTracks(forAlbumId albumId: Int) async throws -> [ITunesResult] {
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(albumId)&entity=song") else {
            return []
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
        
        // Filter out the album itself from the results (we only want the tracks)
        return response.results.filter { $0.wrapperType == "track" }
    }
    
    // 3. Fetch albums for a specific artist
    func fetchAlbums(forArtistId artistId: Int) async throws -> [ITunesResult] {
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(artistId)&entity=album") else {
            return []
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
        
        // Filter out the artist object from the results
        let albums = response.results.filter { $0.wrapperType == "collection" }
        return albums.sorted { ($0.releaseDate ?? "") > ($1.releaseDate ?? "") }
    }
    
    // 4. Fetch recent popular releases
    func fetchRecentReleases() async throws -> [ITunesResult] {
        // The most reliable way to get popular recent releases from iTunes API is to search for a broad term
        // like "2024" or use the top charts. Apple Music RSS is alternative but requires custom models.
        // Let's use a broad term search with &entity=album and limit
        guard let url = URL(string: "https://itunes.apple.com/search?term=new+music&entity=album&limit=25") else {
            return []
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
        
        return response.results.sorted { ($0.releaseDate ?? "") > ($1.releaseDate ?? "") }
    }
    
    // Helper to get high-res artwork
    func highResArtworkUrl(from urlString: String?) -> URL? {
        guard let urlString = urlString else { return nil }
        // The API returns a 100x100 image, but we can simply change the URL to get a 600x600 high-res version!
        let highResString = urlString.replacingOccurrences(of: "100x100bb", with: "600x600bb")
        return URL(string: highResString)
    }
}
