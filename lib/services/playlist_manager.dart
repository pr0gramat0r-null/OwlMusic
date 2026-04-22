import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/track.dart';
import '../models/playlist.dart';

class PlaylistManager {
  static const _fileName = 'playlists.json';
  List<Playlist> _playlists = [];
  final _uuid = const Uuid();

  List<Playlist> get playlists => List.unmodifiable(_playlists);

  Future<void> load() async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/$_fileName');
      if (!await file.exists()) {
        _playlists = [];
        return;
      }
      final jsonStr = await file.readAsString();
      final list = jsonDecode(jsonStr) as List;
      _playlists =
          list.map((e) => Playlist.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _playlists = [];
    }
  }

  Future<void> save() async {
    final dir = await _getDir();
    final file = File('${dir.path}/$_fileName');
    final jsonStr =
        jsonEncode(_playlists.map((p) => p.toJson()).toList());
    await file.writeAsString(jsonStr);
  }

  Playlist createPlaylist(String name) {
    final playlist = Playlist(
      id: _uuid.v4(),
      name: name,
    );
    _playlists.add(playlist);
    save();
    return playlist;
  }

  Playlist? getPlaylist(String id) {
    try {
      return _playlists.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void renamePlaylist(String id, String newName) {
    final idx = _playlists.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _playlists[idx] = _playlists[idx].copyWith(name: newName);
      save();
    }
  }

  void deletePlaylist(String id) {
    _playlists.removeWhere((p) => p.id == id);
    save();
  }

  void addTrackToPlaylist(String playlistId, Track track) {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      _playlists[idx] = _playlists[idx].addTrack(track);
      save();
    }
  }

  void removeTrackFromPlaylist(String playlistId, String trackId) {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      _playlists[idx] = _playlists[idx].removeTrack(trackId);
      save();
    }
  }

  void importPlaylist(String name, List<Track> tracks) {
    final playlist = Playlist(
      id: _uuid.v4(),
      name: name,
      tracks: tracks,
    );
    _playlists.add(playlist);
    save();
  }

  Future<Directory> _getDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/owlmusic');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
