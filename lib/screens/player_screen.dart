import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/player_service.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final h = d.inHours.toString();
      return '$h:$m:$s';
    }
    return '$m:$s';
  }

  IconData _repeatIcon(PlaybackRepeatMode mode) {
    switch (mode) {
      case PlaybackRepeatMode.off:
        return Icons.repeat;
      case PlaybackRepeatMode.all:
        return Icons.repeat;
      case PlaybackRepeatMode.one:
        return Icons.repeat_one;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final player = appState.playerService;
    final track = player.currentTrack;
    final theme = Theme.of(context);

    if (track == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Player'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_note,
                  size: 64, color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 12),
              Text(
                'Nothing playing',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(flex: 1),
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: track.thumbnailUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        track.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, url, error) =>
                            const Icon(Icons.music_note, size: 64),
                      ),
                    )
                  : const Icon(Icons.music_note, size: 64),
            ),
            const SizedBox(height: 32),
            Text(
              track.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              track.artist,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (ctx, snap) {
                final pos = snap.data ?? Duration.zero;
                final dur = player.duration;
                final val = dur.inMilliseconds > 0
                    ? pos.inMilliseconds / dur.inMilliseconds
                    : 0.0;
                return Column(
                  children: [
                    Slider(
                      value: val.clamp(0.0, 1.0),
                      onChanged: (v) {
                        player.seekTo(Duration(
                          milliseconds:
                              (v * dur.inMilliseconds).round(),
                        ));
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(pos)),
                        Text(_formatDuration(dur)),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _repeatIcon(player.repeatMode),
                    color: player.repeatMode != PlaybackRepeatMode.off
                        ? theme.colorScheme.primary
                        : null,
                  ),
                  onPressed: player.toggleRepeat,
                  iconSize: 28,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: player.previous,
                  iconSize: 36,
                ),
                const SizedBox(width: 8),
                StreamBuilder<bool>(
                  stream: player.playingStream,
                  builder: (ctx, snap) {
                    final playing = snap.data ?? false;
                    return IconButton(
                      icon: Icon(
                        playing ? Icons.pause_circle : Icons.play_circle,
                      ),
                      onPressed:
                          playing ? player.pause : player.resume,
                      iconSize: 64,
                      color: theme.colorScheme.primary,
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: player.next,
                  iconSize: 36,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: player.shuffle
                        ? theme.colorScheme.primary
                        : null,
                  ),
                  onPressed: player.toggleShuffle,
                  iconSize: 28,
                ),
              ],
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
