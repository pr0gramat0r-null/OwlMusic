import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit/media_kit.dart';
import 'services/app_state.dart';
import 'services/youtube_service.dart';
import 'services/playlist_manager.dart';
import 'services/player_service.dart';
import 'services/downloader.dart';
import 'screens/home_screen.dart';
import 'screens/playlist_screen.dart';
import 'screens/player_screen.dart';
import 'themes/app_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

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
      theme: AppThemes.lightTheme(),
      darkTheme: AppThemes.darkTheme(),
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
    final hasTrack = appState.currentTrack != null;
    final track = appState.playerService.currentTrack;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          if (hasTrack && _currentIndex != 2) _buildMiniPlayer(appState, track!),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          const NavigationDestination(
            icon: Icon(Icons.queue_music_rounded),
            selectedIcon: Icon(Icons.queue_music_rounded),
            label: 'Playlists',
          ),
          NavigationDestination(
            icon: const Icon(Icons.music_note_rounded),
            selectedIcon: const Icon(Icons.music_note_rounded),
            label: appState.currentTrack != null ? 'Playing' : 'Player',
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer(AppState appState, dynamic track) {
    final theme = Theme.of(context);
    final player = appState.playerService;
    final isPlaying = player.isPlaying;
    final isLoading = appState.isPlayerLoading;

    return Material(
      elevation: 4,
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: () => setState(() => _currentIndex = 2),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (track.thumbnailUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: track.thumbnailUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      width: 44,
                      height: 44,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.music_note, size: 18),
                    ),
                  ),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.music_note, size: 18),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isLoading)
                      Text(
                        'Loading...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      )
                    else if (appState.playerError != null)
                      Text(
                        'Error',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      )
                    else
                      Text(
                        track.artist ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: isPlaying ? player.pause : player.resume,
                  iconSize: 28,
                ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: player.next,
                iconSize: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
