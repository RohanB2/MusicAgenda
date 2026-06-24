import Foundation
import FirebaseFirestore

struct FirebaseAlbum: Codable, Identifiable {
    var id: String
    var title: String
    var artist: String
    var artistId: Int?
    var artworkUrlString: String?
    var releaseDateString: String?
    var totalTimeMillis: Int?
    var isExplicit: Bool
    var rating: Int?
    var dateAdded: Date
    var tracks: [FirebaseTrack]
}

struct FirebaseTrack: Codable, Identifiable {
    var id: String
    var title: String
    var trackNumber: Int
    var isListened: Bool
    var isLiked: Bool
    var playlistTags: [String]
    var trackTimeMillis: Int?
    var isExplicit: Bool
    var note: String?
}
