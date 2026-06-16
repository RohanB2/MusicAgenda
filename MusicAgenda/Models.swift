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
    var artworkUrlString: String?
    
    // A relationship tying this album to multiple tracks. If we delete the album, delete its tracks too.
    @Relationship(deleteRule: .cascade, inverse: \Track.album)
    var tracks: [Track] = []
    
    var dateAdded: Date
    
    init(id: String, title: String, artist: String, artworkUrlString: String? = nil, dateAdded: Date = .now) {
        self.id = id
        self.title = title
        self.artist = artist
        self.artworkUrlString = artworkUrlString
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
    
    var album: Album?
    
    init(id: String, title: String, trackNumber: Int, isListened: Bool = false, isLiked: Bool = false, playlistTags: [String] = []) {
        self.id = id
        self.title = title
        self.trackNumber = trackNumber
        self.isListened = isListened
        self.isLiked = isLiked
        self.playlistTags = playlistTags
    }
}
