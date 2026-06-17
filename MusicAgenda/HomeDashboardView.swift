import SwiftUI
import SwiftData

struct HomeDashboardView: View {
    @Query private var albums: [Album]
    @Binding var selectedNav: NavigationItem?
    
    @State private var showTimeSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("Dashboard")
                    .font(.system(size: 40, weight: .heavy))
                    .padding(.top, 40)
                    .padding(.horizontal, 40)
                
                // Analytics Grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 20)], spacing: 20) {
                    
                    // Total Albums Completed
                    let completed = albums.filter { $0.tracks.count > 0 && $0.tracks.filter(\.isListened).count == $0.tracks.count }
                    Button {
                        selectedNav = .archive
                    } label: {
                        StatCard(title: "Albums Completed", value: "\(completed.count)", icon: "checkmark.seal.fill", color: .green)
                    }
                    .buttonStyle(.plain)
                    
                    // In Progress
                    let inProgress = albums.filter { $0.tracks.count > 0 && $0.tracks.filter(\.isListened).count > 0 && $0.tracks.filter(\.isListened).count < $0.tracks.count }
                    Button {
                        selectedNav = .inProgress
                    } label: {
                        StatCard(title: "In Progress", value: "\(inProgress.count)", icon: "play.circle.fill", color: .blue)
                    }
                    .buttonStyle(.plain)
                    
                    // Top Artist
                    let topArtist = getTopArtist(from: completed)
                    StatCard(title: "Top Artist", value: topArtist, icon: "music.mic", color: .purple)
                    
                    // Total Time Listened
                    let timeString = getTotalTimeListened(from: completed)
                    Button {
                        showTimeSheet = true
                    } label: {
                        StatCard(title: "Time Listened", value: timeString, icon: "clock.fill", color: .orange)
                    }
                    .buttonStyle(.plain)
                    
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showTimeSheet) {
            TimeListenedDetailView()
        }
    }
    
    private func getTopArtist(from albums: [Album]) -> String {
        guard !albums.isEmpty else { return "None" }
        var counts: [String: Int] = [:]
        for album in albums {
            counts[album.artist, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? "None"
    }
    
    private func getTotalTimeListened(from albums: [Album]) -> String {
        let totalMillis = albums.compactMap { $0.totalTimeMillis }.reduce(0, +)
        if totalMillis == 0 { return "0 mins" }
        
        let totalMinutes = totalMillis / 60000
        if totalMinutes > 60 {
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            return "\(hours)h \(mins)m"
        } else {
            return "\(totalMinutes) mins"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title2.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Spacer()
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}
