import 'package:just_audio/just_audio.dart';
import '../models/track.dart';

enum PlaybackRepeatMode { off, all, one }

class PlayerService {
  final AudioPlayer _player = AudioPlayer();
  List<Track> _queue = [];
  int _currentIndex = -1;
  PlaybackRepeatMode _repeatMode = PlaybackRepeatMode.off;
  bool _shuffle = false;

  Track? get currentTrack =>
      (_currentIndex >= 0 && _currentIndex < _queue.length)
          ? _queue[_currentIndex]
          : null;

  List<Track> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  PlaybackRepeatMode get repeatMode => _repeatMode;
  bool get shuffle => _shuffle;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  PlayerService() {
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onTrackComplete();
      }
    });
  }

  void setQueue(List<Track> tracks, {int startIndex = 0}) {
    _queue = List.from(tracks);
    _currentIndex = startIndex;
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
    final track = _queue[_currentIndex];
    try {
      await _player.setUrl(track.url);
      await _player.play();
    } catch (_) {}
  }

  Future<void> resume() async => await _player.play();
  Future<void> pause() async => await _player.pause();
  Future<void> stop() async {
    await _player.stop();
    _currentIndex = -1;
  }

  Future<void> seekTo(Duration position) async =>
      await _player.seek(position);

  Future<void> next() async {
    if (_queue.isEmpty) return;
    if (_shuffle) {
      _currentIndex = (_currentIndex + 1) % _queue.length;
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
    if (_currentIndex > 0) {
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
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
  }

  void dispose() {
    _player.dispose();
  }
}
