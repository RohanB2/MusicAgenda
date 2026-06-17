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
    let trackTimeMillis: Int?
    
    let trackExplicitness: String?
    let collectionExplicitness: String?
}

@Observable
class ITunesAPI {
    static let shared = ITunesAPI()
    // 1. Search for Albums (Smart Search)
    func searchAlbums(query: String, limit: Int = 50) async throws -> [ITunesResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              // Changed back to 'entity=album' because searching songs clogs the limit with random obscure singles
              let url = URL(string: "https://itunes.apple.com/search?term=\(encodedQuery)&entity=album&limit=\(limit)") else {
            return []
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
        // We deduplicate by collectionName to avoid clean/explicit duplicates of the same album
        // BUT we must preserve the original array order because iTunes sorts by relevance/popularity!
        var uniqueAlbumsByName: [String: ITunesResult] = [:]
        var orderedResults: [ITunesResult] = []
        
        for result in response.results {
            guard let name = result.collectionName?.lowercased() else { continue }
            
            if uniqueAlbumsByName[name] == nil {
                uniqueAlbumsByName[name] = result
                orderedResults.append(result)
            } else if result.collectionExplicitness == "explicit" {
                // Prefer explicit version if there's a duplicate, and update it in place to preserve rank
                if let index = orderedResults.firstIndex(where: { $0.collectionName?.lowercased() == name }) {
                    orderedResults[index] = result
                }
                uniqueAlbumsByName[name] = result
            }
        }
        
        return orderedResults
    }
    
    // 1b. Search for Artists
    func searchArtists(query: String) async throws -> [ITunesResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(encodedQuery)&entity=musicArtist&limit=5") else {
            return []
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
        return response.results
    }
    
    // 2. Fetch tracks for a specific album
    func fetchTracks(forAlbumId albumId: Int) async throws -> [ITunesResult] {
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(albumId)&entity=song") else {
            return []
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
        
        // Filter out the album itself and deduplicate tracks by trackNumber (since iTunes sometimes returns clean/explicit tracks together)
        var uniqueTracks: [Int: ITunesResult] = [:]
        for result in response.results where result.wrapperType == "track" {
            if let trackNumber = result.trackNumber {
                if uniqueTracks[trackNumber] == nil {
                    uniqueTracks[trackNumber] = result
                } else if result.trackExplicitness == "explicit" {
                    uniqueTracks[trackNumber] = result
                }
            }
        }
        
        return uniqueTracks.values.sorted { ($0.trackNumber ?? 0) < ($1.trackNumber ?? 0) }
    }
    
    // 3. Fetch albums for a specific artist
    func fetchAlbums(forArtistId artistId: Int) async throws -> [ITunesResult] {
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(artistId)&entity=album") else {
            return []
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
        // Deduplicate by name for artist lookups too
        var uniqueAlbumsByName: [String: ITunesResult] = [:]
        for result in response.results where result.wrapperType == "collection" {
            guard let name = result.collectionName?.lowercased() else { continue }
            if uniqueAlbumsByName[name] == nil {
                uniqueAlbumsByName[name] = result
            } else if result.collectionExplicitness == "explicit" {
                uniqueAlbumsByName[name] = result
            }
        }
        
        return uniqueAlbumsByName.values.sorted { ($0.releaseDate ?? "") > ($1.releaseDate ?? "") }
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
