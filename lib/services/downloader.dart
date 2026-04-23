import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../models/track.dart';

typedef DownloadProgressCallback = void Function(
    String trackId, double progress, String status);

class Downloader {
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();
  DownloadProgressCallback? _onProgress;

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
        print('Download attempt ${attempt + 1} failed for ${track.id}: $e');
        if (attempt == maxRetries - 1) {
          _report(track.id, 0, 'Error: ${e.toString()}');
          return null;
        }
        _report(track.id, 0.05, 'Retrying (${attempt + 2}/$maxRetries)...');
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }
    return null;
  }

  Future<String?> _downloadOnce(Track track) async {
    try {
      _report(track.id, 0.05, 'Fetching stream info...');

      print('Fetching stream manifest for ${track.id}...');
      
      // Add timeout for manifest fetch
      final manifest = await Future.any([
        _yt.videos.streamsClient.getManifest(track.id),
        Future.delayed(const Duration(seconds: 30), () => throw TimeoutException('Manifest fetch timeout'))
      ]) as yt.StreamManifest;
      
      final audioOnly = manifest.audioOnly;
      if (audioOnly.isEmpty) {
        _report(track.id, 0, 'No audio stream available');
        print('No audio stream available for ${track.id}');
        return null;
      }

      final m4a = audioOnly.where((s) => s.container.name == 'm4a');
      final streamInfo =
          m4a.isNotEmpty ? m4a.withHighestBitrate() : audioOnly.withHighestBitrate();

      final ext = streamInfo.container.name;
      final dir = await _getDownloadDir();
      final file = File('${dir.path}/${track.id}.$ext');

      // Check if file exists and is valid
      if (await file.exists()) {
        final length = await file.length();
        if (length > 1024) {  // At least 1KB to be considered valid
          _report(track.id, 1.0, 'Already downloaded');
          print('File already downloaded: ${file.path} ($length bytes)');
          return file.path;
        } else {
          // Delete corrupted/empty file
          print('Deleting corrupted file: ${file.path}');
          await file.delete();
        }
      }

      _report(track.id, 0.1, 'Downloading...');
      print('Downloading audio for ${track.id}...');

      final stream = _yt.videos.streamsClient.get(streamInfo);
      final fileStream = file.openWrite();
      int totalBytes = 0;
      final totalBytesExpected = streamInfo.size.totalBytes;

      try {
        await for (final chunk in stream) {
          fileStream.add(chunk);
          totalBytes += chunk.length;
          if (totalBytesExpected > 0) {
            final pct = totalBytes / totalBytesExpected;
            final pctInt = (pct * 100).toInt();
            _report(track.id, 0.1 + pct * 0.85, 'Downloading $pctInt%...');
          }
        }
      } catch (e) {
        print('Download interrupted for ${track.id}: $e');
        await fileStream.close();
        if (await file.exists()) await file.delete();
        _report(track.id, 0, 'Download interrupted: ${e.toString()}');
        rethrow;
      }

      await fileStream.flush();
      await fileStream.close();

      // Verify the downloaded file
      final finalLength = await file.length();
      if (finalLength < 1024) {
        print('Downloaded file is empty or too small for ${track.id} ($finalLength bytes)');
        await file.delete();
        throw Exception('Downloaded file is empty or too small');
      }

      print('Successfully downloaded ${track.id} to ${file.path} ($finalLength bytes)');
      _report(track.id, 1.0, 'Done');
      return file.path;
    } catch (e) {
      print('Download error for ${track.id}: $e');
      _report(track.id, 0, 'Error: ${e.toString()}');
      return null;
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
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }
    return musicDir;
  }

  void dispose() {
    _yt.close();
  }
}
