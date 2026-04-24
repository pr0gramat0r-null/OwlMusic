import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:path_provider/path_provider.dart';
import '../models/track.dart';
import 'youtube_service.dart';

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
  YouTubeService? _ytService;
  int _playRequestId = 0;

  Track? get currentTrack =>
      (_currentIndex >= 0 && _currentIndex < _queue.length) ? _queue[_currentIndex] : null;

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

  void setYouTubeService(YouTubeService service) {
    _ytService = service;
  }

  void setOnStateChanged(VoidCallback callback) {
    _onStateChanged = callback;
  }

  void _notify() => _onStateChanged?.call();

  Future<void> setQueue(List<Track> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    _queue = List.from(tracks);
    _currentIndex = startIndex.clamp(0, _queue.length - 1).toInt();
    if (_shuffle) _regenerateShuffleOrder();
    await _playCurrent();
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

    final requestId = ++_playRequestId;
    _isLoading = true;
    _error = null;
    _notify();

    final track = _queue[_currentIndex];
    debugPrint('[Player] === Playing: ${track.title} (${track.id}) ===');

    try {
      final opened = await _openBestSource(track.id, requestId);
      if (!opened && requestId == _playRequestId) {
        _isLoading = false;
        _error = 'Could not load audio stream for this track';
        _notify();
      }
    } catch (e) {
      debugPrint('[Player] FAILED: $e');
      if (requestId == _playRequestId) {
        _isLoading = false;
        _error = 'Playback failed: $e';
        _notify();
      }
    }
  }

  Future<bool> _openBestSource(String videoId, int requestId) async {
    final tempFile = await _downloadToTemp(videoId);
    if (requestId != _playRequestId) return true;

    if (tempFile != null) {
      debugPrint('[Player] Opening cached file: ${tempFile.path}');
      await _player.open(mk.Media(tempFile.path));
      return true;
    }

    final streamUrl = await _ytService?.getStreamUrl(videoId);
    if (requestId != _playRequestId) return true;
    if (streamUrl == null || streamUrl.isEmpty) {
      return false;
    }

    debugPrint('[Player] Fallback to stream URL');
    await _player.open(mk.Media(streamUrl));
    return true;
  }

  Future<File?> _downloadToTemp(String videoId) async {
    if (_ytService == null) return null;

    try {
      final dir = await getTemporaryDirectory();
      final cacheDir = Directory('${dir.path}/owlmusic_cache');
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

      final file = File('${cacheDir.path}/$videoId.m4a');
      if (await file.exists() && await file.length() > 0) {
        return file;
      }

      return await _ytService!.downloadBestAudio(videoId, file);
    } catch (e) {
      debugPrint('[Player] _downloadToTemp error: $e');
      return null;
    }
  }

  Future<void> _cleanOldCache() async {
    try {
      final dir = await getTemporaryDirectory();
      final cacheDir = Directory('${dir.path}/owlmusic_cache');
      if (!await cacheDir.exists()) return;
      final entities = await cacheDir.list().where((e) => e is File).toList();
      if (entities.length <= 10) return;
      entities.sort(
        (a, b) => File(a.path).lastModifiedSync().compareTo(File(b.path).lastModifiedSync()),
      );
      for (int i = 0; i < entities.length - 5; i++) {
        try {
          await entities[i].delete();
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> resume() async => await _player.play();
  Future<void> pause() async => await _player.pause();

  Future<void> stop() async {
    _playRequestId++;
    await _player.stop();
    _currentIndex = -1;
    _notify();
  }

  Future<void> seekTo(Duration position) async => await _player.seek(position);
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
    _repeatMode =
        PlaybackRepeatMode.values[(_repeatMode.index + 1) % PlaybackRepeatMode.values.length];
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
  }
}
