import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'services/youtube_service.dart';
import 'services/playlist_manager.dart';
import 'services/player_service.dart';
import 'services/downloader.dart';
import 'screens/home_screen.dart';
import 'screens/playlist_screen.dart';
import 'screens/player_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final youtubeService = YouTubeService();
  final playlistManager = PlaylistManager();
  final playerService = PlayerService();
  final downloader = Downloader();

  final appState = AppState(
    youtubeService: youtubeService,
    playlistManager: playlistManager,
    playerService: playerService,
    downloader: downloader,
  );
  await appState.init();

  runApp(ChangeNotifierProvider.value(
    value: appState,
    child: const OwlMusicApp(),
  ));
}

class OwlMusicApp extends StatelessWidget {
  const OwlMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return MaterialApp(
      title: 'OwlMusic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    PlaylistScreen(),
    PlayerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          const NavigationDestination(
            icon: Icon(Icons.queue_music),
            selectedIcon: Icon(Icons.queue_music),
            label: 'Playlists',
          ),
          NavigationDestination(
            icon: const Icon(Icons.music_note),
            selectedIcon: const Icon(Icons.music_note),
            label: appState.currentTrack != null ? 'Playing' : 'Player',
          ),
        ],
      ),
    );
  }
}
