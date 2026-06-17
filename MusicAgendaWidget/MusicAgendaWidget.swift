import WidgetKit
import SwiftUI
import SwiftData
import AppIntents
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct WidgetTrack: Identifiable {
    let id: String
    let title: String
    let trackNumber: Int
}

struct WidgetAlbum: Identifiable {
    let id: String
    let title: String
    let artist: String
    let artworkData: Data?
    let unlistenedTracks: [WidgetTrack]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), inProgressAlbums: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task {
            let entry = SimpleEntry(date: Date(), inProgressAlbums: await fetchInProgressAlbums())
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            let albums = await fetchInProgressAlbums()
            let entry = SimpleEntry(date: Date(), inProgressAlbums: albums)

            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    private func fetchInProgressAlbums() async -> [WidgetAlbum] {
        let schema = Schema([Album.self, Track.self])
        guard let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.rohanbatra.MusicAgenda")?.appendingPathComponent("MusicAgenda.sqlite") else { return [] }
        let modelConfiguration = ModelConfiguration(schema: schema, url: sharedURL)
        
        guard let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else { return [] }
        let context = ModelContext(container)
        
        let descriptor = FetchDescriptor<Album>(sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        guard let allAlbums = try? context.fetch(descriptor) else { return [] }
        
        var widgetAlbums: [WidgetAlbum] = []
        for album in allAlbums {
            let listenedCount = album.tracks.filter { $0.isListened }.count
            let totalCount = album.tracks.isEmpty ? 1 : album.tracks.count
            
            if listenedCount > 0 && listenedCount < totalCount {
                var data: Data? = nil
                if let urlStr = album.artworkUrlString, let url = URL(string: urlStr) {
                    do {
                        let request = URLRequest(url: url, timeoutInterval: 3.0) // 3 second timeout
                        let (responseData, _) = try await URLSession.shared.data(for: request)
                        data = responseData
                    } catch {
                        print("Widget image fetch failed: \(error)")
                    }
                }
                
                let unlistened = album.tracks.filter { !$0.isListened }.sorted { $0.trackNumber < $1.trackNumber }
                let tracks = unlistened.map { WidgetTrack(id: $0.id, title: $0.title, trackNumber: $0.trackNumber) }
                
                widgetAlbums.append(WidgetAlbum(id: album.id, title: album.title, artist: album.artist, artworkData: data, unlistenedTracks: tracks))
            }
        }
        return widgetAlbums
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let inProgressAlbums: [WidgetAlbum]
}

struct MusicAgendaWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if entry.inProgressAlbums.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.secondary)
                        Text("No In-Progress Albums")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                if family == .systemLarge {
                    VStack(spacing: 12) {
                        if entry.inProgressAlbums.count == 1 {
                            AlbumWidgetRow(album: entry.inProgressAlbums[0], maxTracks: 8)
                        } else if entry.inProgressAlbums.count == 2 {
                            AlbumWidgetRow(album: entry.inProgressAlbums[0], maxTracks: 4)
                            Divider().background(Color.white.opacity(0.2))
                            AlbumWidgetRow(album: entry.inProgressAlbums[1], maxTracks: 4)
                        } else {
                            AlbumWidgetRow(album: entry.inProgressAlbums[0], maxTracks: 2)
                            Divider().background(Color.white.opacity(0.2))
                            AlbumWidgetRow(album: entry.inProgressAlbums[1], maxTracks: 2)
                            Divider().background(Color.white.opacity(0.2))
                            AlbumWidgetRow(album: entry.inProgressAlbums[2], maxTracks: 2)
                        }
                        Spacer(minLength: 0)
                    }
                } else {
                    // systemMedium
                    AlbumWidgetRow(album: entry.inProgressAlbums.first!, maxTracks: 4)
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

struct AlbumWidgetRow: View {
    let album: WidgetAlbum
    let maxTracks: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                if let data = album.artworkData {
                    #if os(macOS)
                    if let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .cornerRadius(6)
                            .shadow(radius: 2)
                    }
                    #else
                    if let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .cornerRadius(6)
                            .shadow(radius: 2)
                    }
                    #endif
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(album.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(album.artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(album.unlistenedTracks.prefix(maxTracks), id: \.id) { track in
                    HStack(spacing: 8) {
                        Button(intent: MarkTrackListenedIntent(trackId: track.id)) {
                            Image(systemName: "circle")
                                .foregroundStyle(.primary)
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.plain)
                        
                        Text("\(track.trackNumber).")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .frame(width: 20, alignment: .trailing)
                        
                        Text(track.title)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

struct WidgetBackgroundView: View {
    var entry: Provider.Entry
    var body: some View {
        Group {
            if let firstAlbum = entry.inProgressAlbums.first, let data = firstAlbum.artworkData {
                #if os(macOS)
                if let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 40)
                        .overlay(Color.black.opacity(0.6))
                }
                #else
                if let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 40)
                        .overlay(Color.black.opacity(0.6))
                }
                #endif
            } else {
                Color.black
            }
        }
    }
}

struct MusicAgendaWidget: Widget {
    let kind: String = "MusicAgendaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(macOS 14.0, iOS 17.0, *) {
                MusicAgendaWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        WidgetBackgroundView(entry: entry)
                    }
            } else {
                MusicAgendaWidgetEntryView(entry: entry)
                    .padding()
                    .background(WidgetBackgroundView(entry: entry))
            }
        }
        .configurationDisplayName("In Progress Albums")
        .description("Keep track of the albums you are currently listening to.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
