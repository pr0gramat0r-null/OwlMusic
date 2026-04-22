import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../models/track.dart';

class YouTubeService {
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();

  Future<List<Track>> search(String query, {int maxResults = 20}) async {
    final searchList = await _yt.search.search(query);

    final tracks = <Track>[];
    final videos = searchList.whereType<yt.Video>().take(maxResults);

    for (final video in videos) {
      tracks.add(Track(
        id: video.id.value,
        title: video.title,
        artist: video.author,
        thumbnailUrl: video.thumbnails.highResUrl,
        url: 'https://www.youtube.com/watch?v=${video.id.value}',
        duration: video.duration,
      ));
    }

    return tracks;
  }

  Future<String?> getStreamUrl(String videoId) async {
    try {
      final manifest =
          await _yt.videos.streamsClient.getManifest(videoId);
      final audioOnly = manifest.audioOnly;
      if (audioOnly.isEmpty) return null;
      final bestAudio = audioOnly.withHighestBitrate();
      return bestAudio.url.toString();
    } catch (_) {
      return null;
    }
  }

  Future<Track?> getTrackInfo(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      return Track(
        id: video.id.value,
        title: video.title,
        artist: video.author,
        thumbnailUrl: video.thumbnails.highResUrl,
        url: 'https://www.youtube.com/watch?v=${video.id.value}',
        duration: video.duration,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    final tracks = <Track>[];
    try {
      await for (final video
          in _yt.playlists.getVideos(playlistId)) {
        tracks.add(Track(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          thumbnailUrl: video.thumbnails.highResUrl,
          url: 'https://www.youtube.com/watch?v=${video.id.value}',
          duration: video.duration,
        ));
      }
    } catch (_) {}
    return tracks;
  }

  void dispose() {
    _yt.close();
  }
}
