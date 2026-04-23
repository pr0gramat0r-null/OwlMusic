import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../models/track.dart';

enum SearchType { all, music, video }

class _BrowserHttpClient extends http.BaseClient {
  final http.Client _inner;
  static const _headers = {
    'user-agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    'cookie': 'CONSENT=YES+cb; VISITOR_INFO1_LIVE=; YSC=; GPS=1',
    'accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'accept-language': 'en-US,en;q=0.7',
    'sec-ch-ua':
        '"Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"Windows"',
    'sec-fetch-dest': 'document',
    'sec-fetch-mode': 'navigate',
    'sec-fetch-site': 'none',
    'sec-fetch-user': '?1',
    'upgrade-insecure-requests': '1',
  };

  _BrowserHttpClient() : _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

class YouTubeService {
  late final yt.YoutubeExplode _yt;
  DateTime? _lastRequestTime;
  static const _minRequestInterval = Duration(milliseconds: 800);

  YouTubeService() {
    _yt = yt.YoutubeExplode(yt.YoutubeHttpClient(_BrowserHttpClient()));
  }

  Future<void> _throttle() async {
    if (_lastRequestTime != null) {
      final diff = DateTime.now().difference(_lastRequestTime!);
      if (diff < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - diff);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  Future<T> _withRetry<T>(Future<T> Function() fn, {int maxAttempts = 3}) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        await _throttle();
        return await fn();
      } on yt.RequestLimitExceededException {
        debugPrint('[YT] Rate limited, attempt ${i + 1}/$maxAttempts');
        if (i == maxAttempts - 1) rethrow;
        final delay = Duration(seconds: (i + 1) * 5);
        debugPrint('[YT] Waiting ${delay.inSeconds}s before retry...');
        await Future.delayed(delay);
      } on yt.TransientFailureException {
        debugPrint('[YT] Transient failure, attempt ${i + 1}/$maxAttempts');
        if (i == maxAttempts - 1) rethrow;
        await Future.delayed(Duration(seconds: (i + 1) * 3));
      }
    }
    throw StateError('Unreachable');
  }

  Future<List<Track>> search(String query,
      {int maxResults = 25, SearchType type = SearchType.music}) async {
    final searchList = await _withRetry(() => _yt.search.search(query));
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

  Future<yt.StreamManifest?> getManifest(String videoId) async {
    try {
      return await _withRetry(
        () => _yt.videos.streamsClient.getManifest(videoId),
      );
    } catch (e) {
      debugPrint('[YT] getManifest failed: $e');
      return null;
    }
  }

  Future<String?> getStreamUrl(String videoId) async {
    final manifest = await getManifest(videoId);
    if (manifest == null) return null;
    final audioOnly = manifest.audioOnly;
    if (audioOnly.isEmpty) return null;
    final m4a = audioOnly.where((s) => s.container.name == 'm4a');
    final best = m4a.isNotEmpty ? m4a.withHighestBitrate() : audioOnly.withHighestBitrate();
    return best.url.toString();
  }

  Future<Track?> getTrackInfo(String videoId) async {
    try {
      final video = await _withRetry(() => _yt.videos.get(videoId));
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
