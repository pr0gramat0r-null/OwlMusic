import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      final playlist = appState.playlistManager.getPlaylist(_openedPlaylistId!);
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
                  Icon(Icons.queue_music,
                      size: 64,
                      color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text(
                    'No playlists yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
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
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlaylistDetail(dynamic playlist, AppState appState) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _openedPlaylistId = null),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_filled),
            tooltip: 'Play all',
            onPressed: () {
              if (playlist.tracks.isNotEmpty) {
                appState.playPlaylist(playlist.tracks);
              }
            },
          ),
        ],
      ),
      body: playlist.tracks.isEmpty
          ? const Center(child: Text('This playlist is empty'))
          : ListView.builder(
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
                );
              },
            ),
    );
  }
}
