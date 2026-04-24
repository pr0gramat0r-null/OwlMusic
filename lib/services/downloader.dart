import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
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
        await Future.delayed(Duration(seconds: (attempt + 1) * 3));
      }
    }
    return null;
  }

  Future<String?> _downloadOnce(Track track) async {
    if (_ytService == null) {
      _report(track.id, 0, 'No YouTube service');
      return null;
    }

    final dir = await _getDownloadDir();
    final file = File('${dir.path}/${track.id}.m4a');

    if (await file.exists() && await file.length() > 0) {
      _report(track.id, 1.0, 'Already downloaded');
      return file.path;
    }

    _report(track.id, 0.1, 'Downloading...');
    final downloadedFile = await _ytService!.downloadBestAudio(
      track.id,
      file,
      onProgress: (progress) {
        _report(
          track.id,
          0.1 + progress * 0.9,
          'Downloading ${(progress * 100).toStringAsFixed(0)}%...',
        );
      },
    );

    if (downloadedFile == null || !await downloadedFile.exists()) {
      _report(track.id, 0, 'Download failed');
      return null;
    }

    final bytes = await downloadedFile.length();
    if (bytes == 0) {
      await downloadedFile.delete();
      _report(track.id, 0, 'Downloaded empty file');
      return null;
    }

    _report(track.id, 1.0, 'Done');
    return downloadedFile.path;
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
