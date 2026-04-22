import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../models/track.dart';

class Downloader {
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();
  double _progress = 0;
  String _status = '';

  double get progress => _progress;
  String get status => _status;

  Future<String?> downloadTrack(Track track) async {
    try {
      _status = 'Fetching stream info...';
      _progress = 0.1;

      final manifest =
          await _yt.videos.streamsClient.getManifest(track.id);
      final audioOnly = manifest.audioOnly;
      if (audioOnly.isEmpty) {
        _status = 'No audio stream available';
        return null;
      }
      final streamInfo = audioOnly.withHighestBitrate();

      _status = 'Downloading...';
      _progress = 0.2;

      final dir = await _getDownloadDir();
      final safeName = _sanitizeFileName(track.title);
      final filePath =
          '$safeName.${streamInfo.audioCodec.contains("opus") ? "opus" : "m4a"}';
      final file = File('${dir.path}/$filePath');
      if (await file.exists()) {
        _status = 'Already downloaded';
        _progress = 1.0;
        return file.path;
      }

      final stream = _yt.videos.streamsClient.get(streamInfo);
      final fileStream = file.openWrite();
      final totalBytes = streamInfo.size.totalBytes;

      int downloadedBytes = 0;
      await for (final chunk in stream) {
        fileStream.add(chunk);
        downloadedBytes += chunk.length;
        _progress = totalBytes > 0 ? downloadedBytes / totalBytes : 0.5;
      }

      await fileStream.flush();
      await fileStream.close();
      _progress = 1.0;
      _status = 'Done';
      return file.path;
    } catch (e) {
      _status = 'Error: $e';
      _progress = 0;
      return null;
    }
  }

  Future<List<String>> downloadPlaylist(List<Track> tracks) async {
    final paths = <String>[];
    for (int i = 0; i < tracks.length; i++) {
      _status = 'Track ${i + 1}/${tracks.length}';
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
