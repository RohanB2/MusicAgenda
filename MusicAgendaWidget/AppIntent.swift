import AppIntents

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
        if let userDefaults = UserDefaults(suiteName: "group.com.rohanbatra.MusicAgenda") {
            var pending = userDefaults.stringArray(forKey: "pendingTrackUpdates") ?? []
            if !pending.contains(trackId) {
                pending.append(trackId)
                userDefaults.set(pending, forKey: "pendingTrackUpdates")
            }
        }
        return .result()
    }
}
