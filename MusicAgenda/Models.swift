//
//  Models.swift
//  MusicAgenda
//
//  Created by Rohan Batra on 6/15/26.
//

import Foundation
import SwiftData

@Model
final class Album {
    @Attribute(.unique) var id: String
    var title: String
    var artist: String
    var artistId: Int?
    var artworkUrlString: String?
    var releaseDateString: String?
    var totalTimeMillis: Int?
    var isExplicit: Bool = false
    var rating: Int? // 1-5 stars
    
    // A relationship tying this album to multiple tracks. If we delete the album, delete its tracks too.
    @Relationship(deleteRule: .cascade, inverse: \Track.album)
    var tracks: [Track] = []
    
    var dateAdded: Date
    
    init(id: String, title: String, artist: String, artistId: Int? = nil, artworkUrlString: String? = nil, releaseDateString: String? = nil, totalTimeMillis: Int? = nil, isExplicit: Bool = false, dateAdded: Date = .now) {
        self.id = id
        self.title = title
        self.artist = artist
        self.artistId = artistId
        self.artworkUrlString = artworkUrlString
        self.releaseDateString = releaseDateString
        self.totalTimeMillis = totalTimeMillis
        self.isExplicit = isExplicit
        self.dateAdded = dateAdded
    }
}

@Model
final class Track {
    @Attribute(.unique) var id: String
    var title: String
    var trackNumber: Int
    var isListened: Bool
    var isLiked: Bool
    var playlistTags: [String]
    var trackTimeMillis: Int?
    var isExplicit: Bool = false
    var note: String?
    
    var album: Album?
    
    init(id: String, title: String, trackNumber: Int, trackTimeMillis: Int? = nil, isExplicit: Bool = false, isListened: Bool = false, isLiked: Bool = false, playlistTags: [String] = []) {
        self.id = id
        self.title = title
        self.trackNumber = trackNumber
        self.trackTimeMillis = trackTimeMillis
        self.isExplicit = isExplicit
        self.isListened = isListened
        self.isLiked = isLiked
        self.playlistTags = playlistTags
    }
}
