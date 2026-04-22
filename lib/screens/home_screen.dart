import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../services/app_state.dart';
import '../widgets/track_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    await context.read<AppState>().search(query);
    if (mounted) setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final results = appState.searchResults;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OwlMusic'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search music on YouTube...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          appState.clearSearch();
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _doSearch(),
            ),
          ),
          if (appState.searchError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                appState.searchError!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.music_note,
                            size: 64,
                            color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text(
                          'Search for your favorite music',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (ctx, i) {
                      final track = results[i];
                      return TrackTile(
                        track: track,
                        isPlaying: appState.currentTrack?.id == track.id,
                        onPlay: () => appState.playTrack(track),
                        onAddToPlaylist: () =>
                            _showAddToPlaylistDialog(track),
                        onDownload: () => appState.downloadTrack(track),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(Track track) {
    final appState = context.read<AppState>();
    final playlists = appState.playlistManager.playlists;

    if (playlists.isEmpty) {
      _showCreatePlaylistDialog(track: track);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add to playlist'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlists.length + 1,
            itemBuilder: (_, i) {
              if (i == playlists.length) {
                return ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Create new playlist'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showCreatePlaylistDialog(track: track);
                  },
                );
              }
              final pl = playlists[i];
              return ListTile(
                title: Text(pl.name),
                subtitle: Text('${pl.trackCount} tracks'),
                onTap: () {
                  appState.addTrackToPlaylist(pl.id, track);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Added to "${pl.name}"')),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog({Track? track}) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New playlist'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final appState = context.read<AppState>();
              final pl = appState.createPlaylist(name);
              if (track != null) {
                appState.addTrackToPlaylist(pl.id, track);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
