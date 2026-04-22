import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/track.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onDownload;
  final bool isPlaying;

  const TrackTile({
    super.key,
    required this.track,
    this.onTap,
    this.onPlay,
    this.onAddToPlaylist,
    this.onDownload,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: track.thumbnailUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: track.thumbnailUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 56,
                  height: 56,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.music_note, size: 24),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 56,
                  height: 56,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.music_note, size: 24),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.music_note, size: 24),
              ),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isPlaying
            ? TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              )
            : null,
      ),
      subtitle: Text(
        '${track.artist}  •  ${track.durationText}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onAddToPlaylist != null)
            IconButton(
              icon: const Icon(Icons.playlist_add, size: 20),
              onPressed: onAddToPlaylist,
              tooltip: 'Add to playlist',
            ),
          if (onDownload != null && !track.downloaded)
            IconButton(
              icon: const Icon(Icons.download, size: 20),
              onPressed: onDownload,
              tooltip: 'Download',
            ),
          if (track.downloaded)
            const Icon(Icons.check_circle, size: 18, color: Colors.green),
        ],
      ),
      onTap: onTap ?? onPlay,
    );
  }
}
