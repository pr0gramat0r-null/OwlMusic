
# 🎵 Owl Music

A modern cross-platform music player application built with **Flutter & Dart**. Download, manage, and listen to your favorite songs with YouTube integration.

## 🚀 Features

- **YouTube Integration** – Search and discover songs directly from YouTube
- **Playlist Management** – Create, organize, and manage custom playlists
- **Local Music Player** – Play downloaded music with intuitive controls
- **Offline Listening** – Download songs for offline playback
- **Cross-platform** – Works on Windows and Android

## 📋 Requirements

- Flutter SDK (3.0 or higher)
- Dart SDK (included with Flutter)
- Windows 10+ or Android 6.0+
- Internet connection for YouTube integration

## 🔧 Tech Stack

- **Framework:** Flutter & Dart
- **State Management:** Provider/Riverpod pattern
- **Platform:** Windows & Android
- **Features:** Local player, YouTube integration, playlist management

## 📦 Project Structure

```
lib/
├── main.dart              # Application entry point
├── models/                # Data models (Playlist, Track)
├── screens/               # UI screens (Home, Player, Playlist)
├── services/              # Business logic (Player, YouTube, Downloader)
├── themes/                # Theme and color configuration
└── widgets/               # Reusable UI components
```

## ⚙️ Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd OwlMusic
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on Windows:**
   ```bash
   flutter run -d windows
   ```

4. **Or run the built executable:**
   ```
   build/windows/x64/runner/Release/owlmusic.exe
   ```

## 🎮 Usage

1. Launch the application
2. Search for songs using YouTube integration
3. Add songs to playlists
4. Download songs for offline listening
5. Use the local player to enjoy your music

## 🛠️ Development

  ```
  flutter build windows --release
  ```