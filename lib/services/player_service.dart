import 'dart:async';
import 'dart:io';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../models/track.dart';

enum PlaybackRepeatMode { off, all, one }

typedef VoidCallback = void Function();

class PlayerService {
  late final mk.Player _player;
  List<Track> _queue = [];
  int _currentIndex = -1;
  PlaybackRepeatMode _repeatMode = PlaybackRepeatMode.off;
  bool _shuffle = false;
  VoidCallback? _onStateChanged;
  bool _isLoading = false;
  String? _error;
  List<int> _shuffledIndices = [];
  int _shufflePosition = -1;
  StreamSubscription? _completedSub;
  StreamSubscription? _playingSub;
  StreamSubscription? _bufferingSub;
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();

  Track? get currentTrack =>
      (_currentIndex >= 0 && _currentIndex < _queue.length)
          ? _queue[_currentIndex]
          : null;

  List<Track> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  PlaybackRepeatMode get repeatMode => _repeatMode;
  bool get shuffle => _shuffle;
  bool get isPlaying => _player.state.playing;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Duration get position => _player.state.position;
  Duration get duration => _player.state.duration;
  double get volume => _player.state.volume / 100.0;
  Stream<Duration> get positionStream => _player.stream.position;
  Stream<bool> get playingStream => _player.stream.playing;
  Stream<Duration> get durationStream => _player.stream.duration;

  PlayerService() {
    _player = mk.Player(
      configuration: const mk.PlayerConfiguration(title: 'OwlMusic'),
    );

    _completedSub = _player.stream.completed.listen((completed) {
      if (completed) _onTrackComplete();
    });

    _playingSub = _player.stream.playing.listen((playing) {
      if (playing && _isLoading) {
        _isLoading = false;
        _error = null;
        _notify();
      }
    });

    _bufferingSub = _player.stream.buffering.listen((buffering) {
      if (!buffering && _isLoading && _player.state.playing) {
        _isLoading = false;
        _error = null;
        _notify();
      }
    });
  }

  void setOnStateChanged(VoidCallback callback) {
    _onStateChanged = callback;
  }

  void _notify() => _onStateChanged?.call();

  void setQueue(List<Track> tracks, {int startIndex = 0}) {
    _queue = List.from(tracks);
    _currentIndex = startIndex;
    if (_shuffle) _regenerateShuffleOrder();
    _playCurrent();
  }

  void addToQueue(Track track) => _queue.add(track);

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (_currentIndex >= _queue.length) _currentIndex = _queue.length - 1;
  }

  Future<void> play(Track track) async {
    _queue = [track];
    _currentIndex = 0;
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;

    _isLoading = true;
    _error = null;
    _notify();

    final track = _queue[_currentIndex];

    try {
      await _downloadAndPlay(track.id);
    } catch (e) {
      print('Playback error for ${track.id}: $e');
      _isLoading = false;
      _error = 'Playback failed: $e';
      _notify();
    }
  }

  Future<void> _downloadAndPlay(String videoId) async {
    try {
      // Clean old cache first to free up space
      await _cleanOldCache();
      
      final tempFile = await _downloadToTemp(videoId);
      if (tempFile != null && await tempFile.exists() && await tempFile.length() > 0) {
        print('Opening media file: ${tempFile.path}');
        await _player.open(mk.Media(tempFile.path));
      } else {
        print('Could not download audio for $videoId');
        _isLoading = false;
        _error = 'Could not download audio. Please try again.';
        _notify();
      }
    } catch (e) {
      print('Error in _downloadAndPlay: $e');
      _isLoading = false;
      _error = 'Playback error: ${e.toString()}';
      _notify();
    }
  }

  Future<File?> _downloadToTemp(String videoId) async {
    try {
      print('Fetching stream manifest for $videoId...');
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioOnly = manifest.audioOnly;
      if (audioOnly.isEmpty) {
        print('No audio stream available for $videoId');
        return null;
      }

      final m4a = audioOnly.where((s) => s.container.name == 'm4a');
      final streamInfo =
          m4a.isNotEmpty ? m4a.withHighestBitrate() : audioOnly.withHighestBitrate();

      final ext = streamInfo.container.name;
      final dir = await getTemporaryDirectory();
      final cacheDir = Directory('${dir.path}/owlmusic_cache');
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

      final file = File('${cacheDir.path}/$videoId.$ext');

      // Check if file exists and is valid
      if (await file.exists()) {
        final length = await file.length();
        if (length > 0) {
          print('Cache hit for $videoId (${length} bytes)');
          return file;
        } else {
          // Delete empty/corrupted file
          print('Deleting corrupted cache file for $videoId');
          await file.delete();
        }
      }

      print('Downloading audio for $videoId...');
      final stream = _yt.videos.streamsClient.get(streamInfo);
      final fileStream = file.openWrite();
      int totalBytes = 0;

      try {
        await for (final chunk in stream) {
          fileStream.add(chunk);
          totalBytes += chunk.length;
        }
      } catch (e) {
        print('Download error for $videoId: $e');
        await fileStream.close();
        if (await file.exists()) await file.delete();
        return null;
      }

      await fileStream.flush();
      await fileStream.close();

      // Verify the downloaded file
      if (await file.length() == 0) {
        print('Downloaded file is empty for $videoId');
        await file.delete();
        return null;
      }

      print('Successfully downloaded $videoId to ${file.path} ($totalBytes bytes)');
      return file;
    } catch (e) {
      print('Download failed for $videoId: $e');
      return null;
    }
  }

  Future<void> _cleanOldCache() async {
    try {
      final dir = await getTemporaryDirectory();
      final cacheDir = Directory('${dir.path}/owlmusic_cache');
      if (!await cacheDir.exists()) return;

      final entities = await cacheDir.list().toList();
      // Keep at least 20 files to avoid excessive cleanup
      if (entities.length <= 20) return;

      // Sort by last modified time (oldest first)
      entities.sort((a, b) =>
          File(a.path).lastModifiedSync().compareTo(File(b.path).lastModifiedSync()));

      // Remove oldest files, keeping the 15 most recent
      for (int i = 0; i < entities.length - 15; i++) {
        try {
          await entities[i].delete();
          print('Cleaned old cache file: ${entities[i].path}');
        } catch (e) {
          print('Failed to delete cache file: $e');
        }
      }
    } catch (e) {
      print('Error cleaning cache: $e');
    }
  }

  Future<void> resume() async => await _player.play();
  Future<void> pause() async => await _player.pause();

  Future<void> stop() async {
    await _player.stop();
    _currentIndex = -1;
    _notify();
  }

  Future<void> seekTo(Duration position) async =>
      await _player.seek(position);

  Future<void> setVolume(double v) async => await _player.setVolume(v * 100);

  Future<void> next() async {
    if (_queue.isEmpty) return;
    if (_shuffle) {
      _shufflePosition++;
      if (_shufflePosition >= _shuffledIndices.length) {
        if (_repeatMode == PlaybackRepeatMode.all) {
          _regenerateShuffleOrder();
          _shufflePosition = 0;
        } else {
          _shufflePosition = _shuffledIndices.length - 1;
          return;
        }
      }
      _currentIndex = _shuffledIndices[_shufflePosition];
    } else if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
    } else if (_repeatMode == PlaybackRepeatMode.all) {
      _currentIndex = 0;
    } else {
      return;
    }
    await _playCurrent();
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    if (_player.state.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_shuffle) {
      _shufflePosition--;
      if (_shufflePosition < 0) {
        if (_repeatMode == PlaybackRepeatMode.all) {
          _shufflePosition = _shuffledIndices.length - 1;
        } else {
          _shufflePosition = 0;
          await _player.seek(Duration.zero);
          return;
        }
      }
      _currentIndex = _shuffledIndices[_shufflePosition];
    } else if (_currentIndex > 0) {
      _currentIndex--;
    } else if (_repeatMode == PlaybackRepeatMode.all) {
      _currentIndex = _queue.length - 1;
    } else {
      await _player.seek(Duration.zero);
      return;
    }
    await _playCurrent();
  }

  void _onTrackComplete() {
    _cleanOldCache();
    switch (_repeatMode) {
      case PlaybackRepeatMode.one:
        _player.seek(Duration.zero);
        _player.play();
        break;
      case PlaybackRepeatMode.all:
        next();
        break;
      case PlaybackRepeatMode.off:
        if (_currentIndex < _queue.length - 1) next();
        break;
    }
  }

  void toggleRepeat() {
    _repeatMode = PlaybackRepeatMode
        .values[(_repeatMode.index + 1) % PlaybackRepeatMode.values.length];
    _notify();
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    if (_shuffle) _regenerateShuffleOrder();
    _notify();
  }

  void _regenerateShuffleOrder() {
    _shuffledIndices = List.generate(_queue.length, (i) => i);
    _shuffledIndices.remove(_currentIndex);
    _shuffledIndices.shuffle();
    _shuffledIndices.insert(0, _currentIndex);
    _shufflePosition = 0;
  }

  void clearError() {
    _error = null;
    _notify();
  }

  void dispose() {
    _completedSub?.cancel();
    _playingSub?.cancel();
    _bufferingSub?.cancel();
    _player.dispose();
    _yt.close();
  }
}
