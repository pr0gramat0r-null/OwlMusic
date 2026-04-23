import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/app_state.dart';
import '../services/player_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  double _volume = 1.0;
  bool _showVolume = false;

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
                'Nothing playing',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Search and play a track to get started',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(track.url),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            tooltip: 'Share URL',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(flex: 1),
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: theme.colorScheme.surfaceContainerHighest,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: track.thumbnailUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: track.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.music_note, size: 64),
                      ),
                    )
                  : const Icon(Icons.music_note, size: 64),
            ),
            const SizedBox(height: 32),
            Text(
              track.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
            const SizedBox(height: 24),
            if (appState.isPlayerLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 3,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loading audio...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else if (appState.playerError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(Icons.error_outline,
                        size: 32, color: theme.colorScheme.error),
                    const SizedBox(height: 8),
                    Text(
                      appState.playerError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () {
                        player.clearError();
                        player.play(track);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else
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
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(pos),
                              style: theme.textTheme.bodySmall),
                          Text(_formatDuration(dur),
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _repeatIcon(player.repeatMode),
                    color: player.repeatMode != PlaybackRepeatMode.off
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: player.toggleRepeat,
                  iconSize: 24,
                  tooltip: 'Repeat',
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  onPressed: player.previous,
                  iconSize: 36,
                  tooltip: 'Previous',
                ),
                const SizedBox(width: 8),
                StreamBuilder<bool>(
                  stream: player.playingStream,
                  builder: (ctx, snap) {
                    final playing = snap.data ?? false;
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                      ),
                      child: IconButton(
                        icon: Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: theme.colorScheme.onPrimary,
                        ),
                        onPressed:
                            playing ? player.pause : player.resume,
                        iconSize: 48,
                        padding: const EdgeInsets.all(8),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: player.next,
                  iconSize: 36,
                  tooltip: 'Next',
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: player.shuffle
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: player.toggleShuffle,
                  iconSize: 24,
                  tooltip: 'Shuffle',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_showVolume)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Icon(Icons.volume_down, size: 18),
                    Expanded(
                      child: Slider(
                        value: _volume,
                        onChanged: (v) {
                          setState(() => _volume = v);
                          player.setVolume(v);
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up, size: 18),
                  ],
                ),
              )
            else
              TextButton.icon(
                onPressed: () =>
                    setState(() => _showVolume = true),
                icon: const Icon(Icons.volume_up, size: 16),
                label: const Text('Volume'),
              ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
