import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../models/track.dart';
import 'youtube_service.dart';

typedef DownloadProgressCallback = void Function(
    String trackId, double progress, String status);

class Downloader {
  YouTubeService? _ytService;
  DownloadProgressCallback? _onProgress;

  void setYouTubeService(YouTubeService service) {
    _ytService = service;
  }

  void setOnProgress(DownloadProgressCallback callback) {
    _onProgress = callback;
  }

  void _report(String trackId, double progress, String status) {
    _onProgress?.call(trackId, progress, status);
  }

  Future<String?> downloadTrack(Track track, {int maxRetries = 3}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await _downloadOnce(track);
      } catch (e) {
        debugPrint('[Downloader] Attempt ${attempt + 1} failed: $e');
        if (attempt == maxRetries - 1) {
          _report(track.id, 0, 'Error: $e');
          return null;
        }
        _report(track.id, 0.05, 'Retrying (${attempt + 2}/$maxRetries)...');
        await Future.delayed(Duration(seconds: (attempt + 1) * 5));
      }
    }
    return null;
  }

  Future<String?> _downloadOnce(Track track) async {
    if (_ytService == null) {
      _report(track.id, 0, 'No YouTube service');
      return null;
    }

    _report(track.id, 0.05, 'Fetching stream info...');

    final manifest = await _ytService!.getManifest(track.id);
    if (manifest == null) {
      _report(track.id, 0, 'Could not get manifest');
      return null;
    }

    final audioOnly = manifest.audioOnly.toList();
    debugPrint('[Downloader] Audio streams: ${audioOnly.length}');

    if (audioOnly.isEmpty) {
      _report(track.id, 0, 'No audio stream');
      return null;
    }

    final m4a = audioOnly.where((s) => s.container.name == 'm4a').toList();
    final streamInfo = m4a.isNotEmpty
        ? m4a.withHighestBitrate()
        : audioOnly.withHighestBitrate();

    final ext = streamInfo.container.name;
    debugPrint('[Downloader] Format: $ext / ${streamInfo.audioCodec}');

    final dir = await _getDownloadDir();
    final file = File('${dir.path}/${track.id}.$ext');

    if (await file.exists() && await file.length() > 0) {
      debugPrint('[Downloader] Exists: ${await file.length()} bytes');
      _report(track.id, 1.0, 'Already downloaded');
      return file.path;
    }

    _report(track.id, 0.1, 'Downloading...');

    final ytClient = yt.YoutubeExplode();
    try {
      final stream = ytClient.videos.streamsClient.get(streamInfo);
      final fileStream = file.openWrite();
      final totalBytes = streamInfo.size.totalBytes;
      int downloadedBytes = 0;

      try {
        await for (final chunk in stream) {
          fileStream.add(chunk);
          downloadedBytes += chunk.length;
          if (totalBytes > 0) {
            final pct = downloadedBytes / totalBytes;
            _report(track.id, 0.1 + pct * 0.85,
                'Downloading ${(pct * 100).toInt()}%...');
          }
        }
      } catch (e) {
        debugPrint('[Downloader] Stream error: $e');
        await fileStream.close();
        if (await file.exists()) await file.delete();
        rethrow;
      }

      await fileStream.flush();
      await fileStream.close();

      final fileSize = await file.length();
      debugPrint('[Downloader] Done: $fileSize bytes');

      if (fileSize == 0) {
        await file.delete();
        throw Exception('Empty file');
      }

      _report(track.id, 1.0, 'Done');
      return file.path;
    } finally {
      ytClient.close();
    }
  }

  Future<List<String>> downloadPlaylist(List<Track> tracks) async {
    final paths = <String>[];
    for (int i = 0; i < tracks.length; i++) {
      _report(tracks[i].id, 0, 'Track ${i + 1}/${tracks.length}');
      final path = await downloadTrack(tracks[i]);
      if (path != null) paths.add(path);
    }
    return paths;
  }

  Future<Directory> _getDownloadDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${dir.path}/owlmusic/downloads');
    if (!await musicDir.exists()) await musicDir.create(recursive: true);
    return musicDir;
  }

  void dispose() {}
}
