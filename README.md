# 🎵 Music Agenda

A premium macOS app for tracking your album listening journey. Search Apple Music's catalog, build your personal listening agenda, and track your progress song by song — all wrapped in a beautiful, native SwiftUI experience.

<!-- 
Add screenshots here once taken:
![Dashboard](screenshots/dashboard.png)
-->

## ✨ Features

### 🔍 Smart Search
- **Two-phase search system** — Searches for both artists and albums simultaneously. Typing an artist name surfaces their full discography; typing an album name finds that specific record.
- **Artist pages** — Click any artist name to browse their complete catalog sorted by release date.
- **Genre browsing** — Explore albums by category when you're looking for something new.

### 📋 Album Tracking
- **Three-stage workflow** — Albums flow through **Agenda** → **In Progress** → **Completed** as you listen.
- **Song-by-song tracking** — Check off individual tracks as you listen, with animated checkboxes and a progress bar.
- **Track notes** — Right-click any track to add personal notes and thoughts.
- **Heart system** — Mark your favorite tracks with a like button.
- **Star ratings** — Rate completed albums on a 5-star scale.

### 🎨 Premium Design
- **Blurred album backgrounds** — Every album detail view features a gorgeous, blurred backdrop pulled from the album artwork (inspired by Apple Music).
- **Frosted glass tracklists** — Track listings sit on macOS's native `ultraThinMaterial` for that premium translucent look.
- **Hover animations** — Subtle scale and shadow effects on album cards and track rows.
- **Deep linking** — Click the play button on any track to open it directly in Apple Music.

### 📊 Dashboard
- **Albums Completed** — Total count of fully listened albums.
- **In Progress** — Albums you're currently working through.
- **Top Artist** — Your most completed artist.
- **Time Listened** — Total listening time calculated from every individual track you've checked off.

### 🧩 Desktop Widgets
- **Medium & Large widgets** — See your in-progress albums right on your desktop.
- **Dynamic track counts** — The large widget intelligently adjusts how many tracks it displays based on how many albums are in progress.
- **Album artwork backgrounds** — Widgets feature the same blurred album art aesthetic as the main app.
- **Interactive toggles** — Mark tracks as listened directly from the widget (requires macOS 14+).

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| **UI Framework** | SwiftUI |
| **Data Persistence** | SwiftData |
| **Music Catalog** | iTunes Search API |
| **Widgets** | WidgetKit + AppIntents |
| **Platforms** | macOS 14+ |

## 📦 Project Structure

```
MusicAgenda/
├── MusicAgendaApp.swift          # App entry point & SwiftData container
├── Models.swift                  # Album & Track data models
├── ContentView.swift             # Main navigation (sidebar + detail)
├── SearchView.swift              # Search UI, genre browsing, smart search
├── SearchAlbumDetailView.swift   # Detail view for search results
├── SavedAlbumDetailView.swift    # Detail view for saved albums
├── LibraryView.swift             # Agenda / In Progress / Archive lists
├── HomeDashboardView.swift       # Dashboard with analytics cards
├── ArtistDetailView.swift        # Artist discography browser
├── RatingSheetView.swift         # Album rating modal
├── TimeListenedDetailView.swift  # Time listened breakdown
├── iTunesAPI.swift               # iTunes Search API client
│
MusicAgendaWidget/
├── MusicAgendaWidget.swift       # Widget timeline, views & configuration
```

## 🚀 Getting Started

### Prerequisites
- **Xcode 15+**
- **macOS 14 (Sonoma)** or later
- A Mac with Apple Silicon or Intel

### Build & Run
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/MusicAgenda.git
   ```
2. Open `MusicAgenda.xcodeproj` in Xcode.
3. Select the **MusicAgenda** scheme and hit **Cmd + R**.

### Install Permanently
1. In Xcode, go to **Product → Scheme → Edit Scheme** and set Build Configuration to `Release`.
2. Hit **Cmd + B** to build.
3. Go to **Product → Show Build Folder in Finder** → `Products/Release/`.
4. Drag `MusicAgenda.app` into your **Applications** folder.

### Widget Setup
1. Launch the app from Applications at least once.
2. Right-click your desktop → **Edit Widgets**.
3. Search for "Music Agenda" and drag it onto your desktop.

## 📝 License

This project is for personal use.
