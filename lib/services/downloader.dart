import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../models/track.dart';

typedef DownloadProgressCallback = void Function(
    String trackId, double progress, String status);

class Downloader {
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();
  double _progress = 0;
  String _status = '';
  DownloadProgressCallback? _onProgress;

  double get progress => _progress;
  String get status => _status;

  void setOnProgress(DownloadProgressCallback callback) {
    _onProgress = callback;
  }

  void _reportProgress(String trackId, double progress, String status) {
    _progress = progress;
    _status = status;
    _onProgress?.call(trackId, progress, status);
  }

  Future<String?> downloadTrack(Track track) async {
    try {
      _reportProgress(track.id, 0.05, 'Fetching stream info...');

      final manifest =
          await _yt.videos.streamsClient.getManifest(track.id);
      final audioOnly = manifest.audioOnly;
      if (audioOnly.isEmpty) {
        _reportProgress(track.id, 0, 'No audio stream available');
        return null;
      }
      final streamInfo = audioOnly.withHighestBitrate();

      _reportProgress(track.id, 0.1, 'Preparing download...');

      final dir = await _getDownloadDir();
      final safeName = _sanitizeFileName(track.title);
      final ext =
          streamInfo.audioCodec.contains('opus') ? 'opus' : 'm4a';
      final filePath = '$safeName.$ext';
      final file = File('${dir.path}/$filePath');

      if (await file.exists()) {
        _reportProgress(track.id, 1.0, 'Already downloaded');
        return file.path;
      }

      _reportProgress(track.id, 0.15, 'Downloading...');

      final stream = _yt.videos.streamsClient.get(streamInfo);
      final fileStream = file.openWrite();
      final totalBytes = streamInfo.size.totalBytes;

      int downloadedBytes = 0;
      int lastReported = 0;
      await for (final chunk in stream) {
        fileStream.add(chunk);
        downloadedBytes += chunk.length;
        final pct = totalBytes > 0 ? downloadedBytes / totalBytes : 0.5;
        final pctInt = (pct * 100).toInt();
        if (pctInt != lastReported && pctInt % 5 == 0) {
          lastReported = pctInt;
          _reportProgress(track.id, 0.15 + pct * 0.85,
              'Downloading $pctInt%...');
        }
      }

      await fileStream.flush();
      await fileStream.close();
      _reportProgress(track.id, 1.0, 'Done');
      return file.path;
    } catch (e) {
      _reportProgress(track.id, 0, 'Error: $e');
      return null;
    }
  }

  Future<List<String>> downloadPlaylist(List<Track> tracks) async {
    final paths = <String>[];
    for (int i = 0; i < tracks.length; i++) {
      _reportProgress(
          tracks[i].id, 0, 'Track ${i + 1}/${tracks.length}');
      final path = await downloadTrack(tracks[i]);
      if (path != null) paths.add(path);
    }
    return paths;
  }

  Future<Directory> _getDownloadDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${dir.path}/owlmusic/downloads');
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }
    return musicDir;
  }

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void dispose() {
    _yt.close();
  }
}
