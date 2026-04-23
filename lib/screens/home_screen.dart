import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../services/app_state.dart';
import '../services/youtube_service.dart';
import '../widgets/track_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _searchController.text.isEmpty) {
        setState(() => _showSuggestions = true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _showSuggestions = false);
    _focusNode.unfocus();
    await context.read<AppState>().search(query);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final results = appState.searchResults;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note_rounded,
                color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 6),
            Text('OwlMusic',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              appState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: appState.toggleDarkMode,
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Search music on YouTube...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: appState.isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          appState.clearSearch();
                          setState(() => _showSuggestions = false);
                        },
                      ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _doSearch(),
              onChanged: (val) {
                setState(() => _showSuggestions = val.isEmpty && _focusNode.hasFocus);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _searchTypeChip(appState, SearchType.music, 'Music'),
                const SizedBox(width: 8),
                _searchTypeChip(appState, SearchType.all, 'All'),
                const SizedBox(width: 8),
                _searchTypeChip(appState, SearchType.video, 'Video'),
              ],
            ),
          ),
          if (appState.searchError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 18, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appState.searchError!,
                      style: TextStyle(color: theme.colorScheme.error),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _doSearch,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _showSuggestions && results.isEmpty
                ? _buildSuggestions(appState, theme)
                : results.isEmpty && !appState.isSearching
                    ? _buildEmptyState(appState, theme)
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 80),
                        itemCount: results.length,
                        itemBuilder: (ctx, i) {
                          final track = results[i];
                          return TrackTile(
                            track: track,
                            isPlaying:
                                appState.currentTrack?.id == track.id,
                            onPlay: () => appState.playTrack(track),
                            onAddToPlaylist: () =>
                                _showAddToPlaylistDialog(track),
                            onDownload: () =>
                                appState.downloadTrack(track),
                            downloadProgress: appState
                                .getDownloadProgress(track.id),
                            isDownloaded:
                                appState.isTrackDownloaded(track.id),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _searchTypeChip(AppState appState, SearchType type, String label) {
    final isSelected = appState.searchType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        appState.setSearchType(type);
        if (_searchController.text.isNotEmpty) {
          _doSearch();
        }
      },
    );
  }

  Widget _buildSuggestions(AppState appState, ThemeData theme) {
    final suggestions = appState.searchCache;
    final history = appState.listenHistory;

    if (suggestions.isEmpty && history.isEmpty) {
      return _buildEmptyState(appState, theme);
    }

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      children: [
        if (suggestions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Recent searches',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ),
          ...suggestions.take(5).map((q) => ListTile(
                leading: const Icon(Icons.history_rounded, size: 20),
                title: Text(q),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () =>
                      appState.removeSearchSuggestion(q),
                ),
                onTap: () {
                  _searchController.text = q;
                  _doSearch();
                },
              )),
        ],
        if (history.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Listen history',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
                TextButton(
                  onPressed: () => appState.clearHistory(),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          ...history.take(10).map((track) => TrackTile(
                track: track,
                isPlaying: appState.currentTrack?.id == track.id,
                onPlay: () => appState.playTrack(track),
                onDownload: () => appState.downloadTrack(track),
                downloadProgress:
                    appState.getDownloadProgress(track.id),
                isDownloaded: appState.isTrackDownloaded(track.id),
              )),
        ],
      ],
    );
  }

  Widget _buildEmptyState(AppState appState, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.music_note_rounded,
                size: 40,
                color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Text(
            'Find your favorite music',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Search by song, artist, or album',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add to playlist',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...playlists.map((pl) => ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.queue_music_rounded,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                  ),
                  title: Text(pl.name),
                  subtitle: Text('${pl.trackCount} tracks'),
                  onTap: () {
                    appState.addTrackToPlaylist(pl.id, track);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Added to "${pl.name}"'),
                          duration: const Duration(seconds: 2)),
                    );
                  },
                )),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_rounded),
              ),
              title: const Text('Create new playlist'),
              onTap: () {
                Navigator.pop(ctx);
                _showCreatePlaylistDialog(track: track);
              },
            ),
          ],
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
          decoration: const InputDecoration(hintText: 'Playlist name'),
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
