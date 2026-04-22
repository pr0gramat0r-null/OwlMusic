import 'package:flutter/material.dart';
import '../models/playlist.dart';

class PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;

  const PlaylistTile({
    super.key,
    required this.playlist,
    this.onTap,
    this.onDelete,
    this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.queue_music,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        playlist.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${playlist.trackCount} tracks  •  ${playlist.totalDurationText}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'rename':
              onRename?.call();
              break;
            case 'delete':
              onDelete?.call();
              break;
          }
        },
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: 'rename', child: Text('Rename')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
      onTap: onTap,
    );
  }
}
