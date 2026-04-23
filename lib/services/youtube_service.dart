import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../models/track.dart';

enum SearchType { all, music, video }

class YouTubeService {
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();

  Future<List<Track>> search(String query,
      {int maxResults = 25, SearchType type = SearchType.music}) async {
    final searchList = await _yt.search.search(query);
    var videos = searchList.whereType<yt.Video>().toList();
    videos = _filterAndSort(videos, type);

    final tracks = <Track>[];
    for (final video in videos.take(maxResults)) {
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

  List<yt.Video> _filterAndSort(List<yt.Video> videos, SearchType type) {
    switch (type) {
      case SearchType.all:
        return videos;
      case SearchType.music:
        final filtered = videos.where((v) {
          final dur = v.duration;
          if (dur != null) {
            final secs = dur.inSeconds;
            if (secs < 30) return false;
            if (secs > 3600) return false;
          }
          return true;
        }).toList();
        filtered.sort((a, b) => _musicScore(b).compareTo(_musicScore(a)));
        return filtered;
      case SearchType.video:
        return videos.where((v) {
          final dur = v.duration;
          if (dur != null && dur.inSeconds < 10) return false;
          return true;
        }).toList();
    }
  }

  double _musicScore(yt.Video video) {
    double score = 0.0;
    final t = video.title.toLowerCase();
    final a = video.author.toLowerCase();

    if (t.contains('official')) score += 3;
    if (t.contains('lyric')) score += 2;
    if (t.contains('audio')) score += 2;
    if (t.contains('music video')) score += 2;
    if (t.contains('mv')) score += 1;
    if (t.contains('cover')) score += 1;
    if (t.contains('remix')) score += 1;
    if (t.contains('feat') || t.contains('ft.')) score += 1;
    if (a.contains('vevo')) score += 3;
    if (a.contains('official')) score += 2;
    if (a.contains('topic')) score += 2;
    if (a.contains('music')) score += 1;
    if (a.contains('records')) score += 1;
    if (t.contains('trailer') ||
        t.contains('tutorial') ||
        t.contains('review') ||
        t.contains('vlog') ||
        t.contains('reaction')) {
      score -= 5;
    }
    if (video.duration != null) {
      final secs = video.duration!.inSeconds;
      if (secs >= 120 && secs <= 480) {
        score += 2;
      } else if (secs >= 30 && secs <= 600) {
        score += 1;
      }
    }
    return score;
  }

  Future<String?> getStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioOnly = manifest.audioOnly;
      if (audioOnly.isEmpty) return null;

      final m4a = audioOnly.where((s) => s.container.name == 'm4a');
      final bestAudio =
          m4a.isNotEmpty ? m4a.withHighestBitrate() : audioOnly.withHighestBitrate();
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
      await for (final video in _yt.playlists.getVideos(playlistId)) {
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
