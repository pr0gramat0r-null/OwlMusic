import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../services/app_state.dart';
import '../widgets/playlist_tile.dart';
import '../widgets/track_tile.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  String? _openedPlaylistId;

  void _showCreatePlaylistDialog() {
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
              context.read<AppState>().createPlaylist(name);
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(String playlistId, String currentName) {
    final nameCtrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename playlist'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(hintText: 'New name'),
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
              context.read<AppState>().renamePlaylist(playlistId, name);
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String playlistId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete playlist?'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppState>().deletePlaylist(playlistId);
              Navigator.pop(ctx);
              if (_openedPlaylistId == playlistId) {
                setState(() => _openedPlaylistId = null);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final playlists = appState.playlistManager.playlists;

    if (_openedPlaylistId != null) {
      final playlist =
          appState.playlistManager.getPlaylist(_openedPlaylistId!);
      if (playlist == null) {
        _openedPlaylistId = null;
      } else {
        return _buildPlaylistDetail(playlist, appState);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        centerTitle: true,
      ),
      body: playlists.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.queue_music_rounded,
                        size: 40,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No playlists yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create one to organize your music',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: playlists.length,
              itemBuilder: (ctx, i) {
                final pl = playlists[i];
                return PlaylistTile(
                  playlist: pl,
                  onTap: () =>
                      setState(() => _openedPlaylistId = pl.id),
                  onRename: () => _showRenameDialog(pl.id, pl.name),
                  onDelete: () => _confirmDelete(pl.id, pl.name),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePlaylistDialog,
        tooltip: 'Create playlist',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildPlaylistDetail(dynamic playlist, AppState appState) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() => _openedPlaylistId = null),
        ),
        actions: [
          if (playlist.tracks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_circle_filled_rounded),
              tooltip: 'Play all',
              onPressed: () {
                appState.playPlaylist(playlist.tracks);
              },
            ),
          if (playlist.tracks.isNotEmpty)
              IconButton(
              icon: const Icon(Icons.shuffle_rounded),
              tooltip: 'Shuffle play',
              onPressed: () {
                final shuffled = List<Track>.of(playlist.tracks)..shuffle();
                appState.playPlaylist(shuffled);
              },
            ),
        ],
      ),
      body: playlist.tracks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.music_note_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(
                    'This playlist is empty',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 80),
              itemCount: playlist.tracks.length,
              itemBuilder: (ctx, i) {
                final track = playlist.tracks[i];
                return TrackTile(
                  track: track,
                  isPlaying: appState.currentTrack?.id == track.id,
                  onPlay: () => appState.playPlaylist(
                    playlist.tracks,
                    startIndex: i,
                  ),
                  onDownload: () => appState.downloadTrack(track),
                  downloadProgress:
                      appState.getDownloadProgress(track.id),
                  isDownloaded: appState.isTrackDownloaded(track.id),
                );
              },
            ),
    );
  }
}
