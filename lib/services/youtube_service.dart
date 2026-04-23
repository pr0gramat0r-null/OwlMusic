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

        filtered.sort((a, b) {
          final scoreA = _musicScore(a);
          final scoreB = _musicScore(b);
          return scoreB.compareTo(scoreA);
        });

        return filtered;
      case SearchType.video:
        final filtered = videos.where((v) {
          final dur = v.duration;
          if (dur != null && dur.inSeconds < 10) return false;
          return true;
        }).toList();
        return filtered;
    }
  }

  double _musicScore(yt.Video video) {
    double score = 0.0;
    final lowerTitle = video.title.toLowerCase();
    final lowerAuthor = video.author.toLowerCase();

    if (lowerTitle.contains('official')) score += 3;
    if (lowerTitle.contains('lyric')) score += 2;
    if (lowerTitle.contains('audio')) score += 2;
    if (lowerTitle.contains('music video')) score += 2;
    if (lowerTitle.contains('mv')) score += 1;
    if (lowerTitle.contains('cover')) score += 1;
    if (lowerTitle.contains('remix')) score += 1;
    if (lowerTitle.contains('feat') || lowerTitle.contains('ft.')) score += 1;
    if (lowerAuthor.contains('vevo')) score += 3;
    if (lowerAuthor.contains('official')) score += 2;
    if (lowerAuthor.contains('topic')) score += 2;
    if (lowerAuthor.contains('music')) score += 1;
    if (lowerAuthor.contains('records')) score += 1;

    if (lowerTitle.contains('trailer') ||
        lowerTitle.contains('tutorial') ||
        lowerTitle.contains('review') ||
        lowerTitle.contains('vlog') ||
        lowerTitle.contains('reaction')) {
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
