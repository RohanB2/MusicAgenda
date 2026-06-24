import Foundation
import FirebaseFirestore
import FirebaseAuth
import Observation
import WidgetKit

struct WidgetTrack: Codable, Identifiable {
    let id: String
    let title: String
    let trackNumber: Int
}

struct WidgetAlbum: Codable, Identifiable {
    let id: String
    let title: String
    let artist: String
    let artworkData: Data?
    let unlistenedTracks: [WidgetTrack]
}

@Observable
class FirestoreManager {
    var albums: [FirebaseAlbum] = []
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private var userDefaultsObserver: NSObjectProtocol?
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    func startListening() {
        guard let uid = currentUserId else { return }
        
        listenerRegistration = db.collection("users").document(uid).collection("albums")
            .order(by: "dateAdded", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self?.albums = documents.compactMap { doc -> FirebaseAlbum? in
                    try? doc.data(as: FirebaseAlbum.self)
                }
                
                self?.processPendingWidgetUpdates()
                self?.syncWidgetData()
            }
            
        userDefaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.processPendingWidgetUpdates()
        }
    }
    
    func stopListening() {
        listenerRegistration?.remove()
        if let observer = userDefaultsObserver {
            NotificationCenter.default.removeObserver(observer)
            userDefaultsObserver = nil
        }
    }
    
    func addAlbum(_ album: FirebaseAlbum) {
        guard let uid = currentUserId else { return }
        do {
            try db.collection("users").document(uid).collection("albums").document(album.id).setData(from: album)
        } catch {
            print("Error adding album: \(error)")
        }
    }
    
    func deleteAlbum(_ album: FirebaseAlbum) {
        guard let uid = currentUserId else { return }
        db.collection("users").document(uid).collection("albums").document(album.id).delete()
    }
    
    // MARK: - Widget Synchronization
    
    private func syncWidgetData() {
        // Find top 3 in-progress albums
        let inProgress = albums.filter { album in
            let listenedCount = album.tracks.filter { $0.isListened }.count
            let totalCount = album.tracks.isEmpty ? 1 : album.tracks.count
            return listenedCount > 0 && listenedCount < totalCount
        }.prefix(3)
        
        Task {
            let userDefaults = UserDefaults(suiteName: "group.com.rohanbatra.MusicAgenda")
            let existingData = userDefaults?.data(forKey: "widgetAlbums")
            let existingAlbums = (try? JSONDecoder().decode([WidgetAlbum].self, from: existingData ?? Data())) ?? []
            
            var widgetAlbums: [WidgetAlbum] = []
            for album in inProgress {
                var data: Data? = existingAlbums.first(where: { $0.id == album.id })?.artworkData
                
                if data == nil, let urlStr = album.artworkUrlString, let url = URL(string: urlStr) {
                    if let (responseData, _) = try? await URLSession.shared.data(from: url) {
                        data = responseData
                    }
                }
                
                let unlistened = album.tracks.filter { !$0.isListened }.sorted { $0.trackNumber < $1.trackNumber }
                let tracks = unlistened.map { WidgetTrack(id: $0.id, title: $0.title, trackNumber: $0.trackNumber) }
                
                widgetAlbums.append(WidgetAlbum(id: album.id, title: album.title, artist: album.artist, artworkData: data, unlistenedTracks: tracks))
            }
            
            if let userDefaults = UserDefaults(suiteName: "group.com.rohanbatra.MusicAgenda") {
                // Reconcile pending tracks - remove them from pending only if they are no longer in the unlistened tracks
                var pending = userDefaults.stringArray(forKey: "pendingTrackUpdates") ?? []
                let allUnlistenedTrackIds = widgetAlbums.flatMap { $0.unlistenedTracks.map { $0.id } }
                pending.removeAll { !allUnlistenedTrackIds.contains($0) }
                userDefaults.set(pending, forKey: "pendingTrackUpdates")
                
                if let encoded = try? JSONEncoder().encode(widgetAlbums) {
                    userDefaults.set(encoded, forKey: "widgetAlbums")
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        }
    }
    
    func processPendingWidgetUpdates() {
        guard let userDefaults = UserDefaults(suiteName: "group.com.rohanbatra.MusicAgenda") else { return }
        let pending = userDefaults.stringArray(forKey: "pendingTrackUpdates") ?? []
        guard !pending.isEmpty else { return }
        
        var modifiedAlbums = [FirebaseAlbum]()
        
        for trackId in pending {
            if let index = albums.firstIndex(where: { album in album.tracks.contains(where: { $0.id == trackId }) }) {
                var updatedAlbum = albums[index]
                if let trackIndex = updatedAlbum.tracks.firstIndex(where: { $0.id == trackId }) {
                    if !updatedAlbum.tracks[trackIndex].isListened {
                        updatedAlbum.tracks[trackIndex].isListened = true
                        modifiedAlbums.append(updatedAlbum)
                    }
                }
            }
        }
        
        // Write back to Firestore
        for album in modifiedAlbums {
            addAlbum(album)
        }
        
        // Note: We deliberately do NOT clear pending updates here! 
        // syncWidgetData() will clear them once Firestore confirms the change and the widget data is re-calculated.
    }
}
