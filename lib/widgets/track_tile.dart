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
  final double downloadProgress;
  final bool isDownloaded;

  const TrackTile({
    super.key,
    required this.track,
    this.onTap,
    this.onPlay,
    this.onAddToPlaylist,
    this.onDownload,
    this.isPlaying = false,
    this.downloadProgress = 0,
    this.isDownloaded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDownloading = downloadProgress > 0 && downloadProgress < 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap ?? onPlay,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: track.thumbnailUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: track.thumbnailUrl,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 52,
                                height: 52,
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.music_note, size: 20),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 52,
                                height: 52,
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.music_note, size: 20),
                              ),
                            )
                          : Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.music_note, size: 20),
                            ),
                    ),
                    if (isPlaying)
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.equalizer,
                          color: theme.colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: isPlaying
                            ? TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              )
                            : theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${track.artist}  •  ${track.durationText}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isDownloading) ...[
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: downloadProgress,
                            minHeight: 3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                if (isDownloaded)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.offline_pin,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  )
                else if (isDownloading)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: downloadProgress,
                      ),
                    ),
                  )
                else if (onDownload != null)
                  IconButton(
                    icon: const Icon(Icons.download_outlined, size: 20),
                    onPressed: onDownload,
                    tooltip: 'Download',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                if (onAddToPlaylist != null)
                  IconButton(
                    icon: const Icon(Icons.playlist_add, size: 20),
                    onPressed: onAddToPlaylist,
                    tooltip: 'Add to playlist',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
