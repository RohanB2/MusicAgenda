import WidgetKit
import AppIntents
import SwiftData

struct MarkTrackListenedIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Track Listened"
    static var description = IntentDescription("Marks a specific track as listened.")

    @Parameter(title: "Track ID")
    var trackId: String

    init() {}

    init(trackId: String) {
        self.trackId = trackId
    }

    func perform() async throws -> some IntentResult {
        // Fetch from shared container
        let schema = Schema([Album.self, Track.self])
        let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.rohanbatra.MusicAgenda")!.appendingPathComponent("MusicAgenda.sqlite")
        let modelConfiguration = ModelConfiguration(schema: schema, url: sharedURL)
        
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = ModelContext(container)
        
        // Find the track and update it
        let descriptor = FetchDescriptor<Track>(predicate: #Predicate { $0.id == trackId })
        if let track = try? context.fetch(descriptor).first {
            track.isListened = true
            try? context.save()
        }
        
        return .result()
    }
}
