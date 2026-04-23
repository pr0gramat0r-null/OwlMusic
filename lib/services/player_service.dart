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
  Future<String?> Function(String videoId)? _urlResolver;
  VoidCallback? _onStateChanged;
  bool _isLoading = false;
  String? _error;
  List<int> _shuffledIndices = [];
  int _shufflePosition = -1;
  StreamSubscription? _completedSub;
  StreamSubscription? _playingSub;
  StreamSubscription? _errorSub;
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();

  static const _ytHeaders = {
    'User-Agent':
        'com.google.android.youtube/17.36.4 (Linux; U; Android 12; GB) gzip',
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.5',
  };

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
      if (completed) {
        _onTrackComplete();
      }
    });

    _playingSub = _player.stream.playing.listen((playing) {
      if (playing && _isLoading) {
        _isLoading = false;
        _error = null;
        _notify();
      }
    });

    _errorSub = _player.stream.error.listen((err) {
      if (err.isNotEmpty && _isLoading) {
        _isLoading = false;
        _error = 'Stream failed, downloading instead...';
        _notify();
        _fallbackDownloadAndPlay();
      }
    });
  }

  void setUrlResolver(Future<String?> Function(String videoId) resolver) {
    _urlResolver = resolver;
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

  void addToQueue(Track track) {
    _queue.add(track);
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (_currentIndex >= _queue.length) {
      _currentIndex = _queue.length - 1;
    }
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
      String? streamUrl;

      if (_urlResolver != null) {
        streamUrl = await _urlResolver!(track.id);
      }

      if (streamUrl != null) {
        _queue[_currentIndex] = track.copyWith(url: streamUrl);

        final nativePlayer = _player.platform;
        if (nativePlayer != null) {
          await (nativePlayer as dynamic).setProperty(
            'http-header-fields',
            'User-Agent: ${_ytHeaders['User-Agent']}',
            waitForInitialization: true,
          );
        }

        await _player.open(
          mk.Media(streamUrl, httpHeaders: _ytHeaders),
        );

        await Future.delayed(const Duration(seconds: 3));
        if (_isLoading && !_player.state.playing && _player.state.duration == Duration.zero) {
          _isLoading = false;
          _error = null;
          _notify();
          await _fallbackDownloadAndPlay();
          return;
        }
      } else {
        await _fallbackDownloadAndPlay();
      }
    } catch (e) {
      _isLoading = false;
      _error = null;
      _notify();
      await _fallbackDownloadAndPlay();
    }
  }

  Future<void> _fallbackDownloadAndPlay() async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;

    final track = _queue[_currentIndex];
    _isLoading = true;
    _error = null;
    _notify();

    try {
      final tempFile = await _downloadToTemp(track.id);
      if (tempFile != null) {
        await _player.open(mk.Media(tempFile.path));
      } else {
        _isLoading = false;
        _error = 'Could not download audio';
        _notify();
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Playback failed';
      _notify();
    }
  }

  Future<File?> _downloadToTemp(String videoId) async {
    try {
      final manifest =
          await _yt.videos.streamsClient.getManifest(videoId);
      final audioOnly = manifest.audioOnly;
      if (audioOnly.isEmpty) return null;

      final streamInfo = audioOnly.withHighestBitrate();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/owlmusic_temp_$videoId.m4a');

      if (await file.exists()) {
        return file;
      }

      final stream = _yt.videos.streamsClient.get(streamInfo);
      final fileStream = file.openWrite();

      await for (final chunk in stream) {
        fileStream.add(chunk);
      }

      await fileStream.flush();
      await fileStream.close();
      return file;
    } catch (_) {
      return null;
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
    switch (_repeatMode) {
      case PlaybackRepeatMode.one:
        _player.seek(Duration.zero);
        _player.play();
        break;
      case PlaybackRepeatMode.all:
        next();
        break;
      case PlaybackRepeatMode.off:
        if (_currentIndex < _queue.length - 1) {
          next();
        }
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
    if (_shuffle) {
      _regenerateShuffleOrder();
    }
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
    _errorSub?.cancel();
    _player.dispose();
    _yt.close();
  }
}
