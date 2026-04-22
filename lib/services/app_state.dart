import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/track.dart';
import '../models/playlist.dart';
import 'youtube_service.dart';
import 'playlist_manager.dart';
import 'player_service.dart';
import 'downloader.dart';

class AppState extends ChangeNotifier {
  final YouTubeService youtubeService;
  final PlaylistManager playlistManager;
  final PlayerService playerService;
  final Downloader downloader;

  List<Track> _searchResults = [];
  String? _searchError;
  List<Track> _listenHistory = [];
  List<String> _searchCache = [];
  bool _isDarkMode = false;

  AppState({
    required this.youtubeService,
    required this.playlistManager,
    required this.playerService,
    required this.downloader,
  });

  List<Track> get searchResults => _searchResults;
  String? get searchError => _searchError;
  List<Track> get listenHistory => List.unmodifiable(_listenHistory);
  List<String> get searchCache => List.unmodifiable(_searchCache);
  bool get isDarkMode => _isDarkMode;
  Track? get currentTrack => playerService.currentTrack;

  Future<void> init() async {
    await playlistManager.load();
    await _loadPrefs();
    await _loadHistory();
  }

  Future<void> search(String query) async {
    _searchError = null;
    notifyListeners();
    try {
      _searchResults = await youtubeService.search(query);
      if (!_searchCache.contains(query)) {
        _searchCache.insert(0, query);
        if (_searchCache.length > 20) _searchCache.removeLast();
      }
    } catch (e) {
      _searchError = 'Search failed: $e';
      _searchResults = [];
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _searchError = null;
    notifyListeners();
  }

  Future<void> playTrack(Track track) async {
    final streamUrl = await youtubeService.getStreamUrl(track.id);
    if (streamUrl != null) {
      final playable = track.copyWith(url: streamUrl);
      await playerService.play(playable);
    } else {
      await playerService.play(track);
    }
    _addToHistory(track);
    notifyListeners();
  }

  Future<void> playPlaylist(List<Track> tracks, {int startIndex = 0}) async {
    final playableTracks = <Track>[];
    for (final t in tracks) {
      final streamUrl = await youtubeService.getStreamUrl(t.id);
      playableTracks.add(
        streamUrl != null ? t.copyWith(url: streamUrl) : t,
      );
    }
    playerService.setQueue(playableTracks, startIndex: startIndex);
    if (playableTracks.isNotEmpty && startIndex < playableTracks.length) {
      _addToHistory(playableTracks[startIndex]);
    }
    notifyListeners();
  }

  void _addToHistory(Track track) {
    _listenHistory.removeWhere((t) => t.id == track.id);
    _listenHistory.insert(0, track);
    if (_listenHistory.length > 50) _listenHistory.removeLast();
    _saveHistory();
  }

  Future<void> downloadTrack(Track track) async {
    final path = await downloader.downloadTrack(track);
    if (path != null) {
      notifyListeners();
    }
  }

  Playlist createPlaylist(String name) {
    final pl = playlistManager.createPlaylist(name);
    notifyListeners();
    return pl;
  }

  void addTrackToPlaylist(String playlistId, Track track) {
    playlistManager.addTrackToPlaylist(playlistId, track);
    notifyListeners();
  }

  void removeTrackFromPlaylist(String playlistId, String trackId) {
    playlistManager.removeTrackFromPlaylist(playlistId, trackId);
    notifyListeners();
  }

  void renamePlaylist(String id, String newName) {
    playlistManager.renamePlaylist(id, newName);
    notifyListeners();
  }

  void deletePlaylist(String id) {
    playlistManager.deletePlaylist(id);
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _savePrefs();
    notifyListeners();
  }

  Future<void> _loadPrefs() async {
    try {
      final dir = await _getAppDir();
      final file = File('${dir.path}/prefs.json');
      if (await file.exists()) {
        final data =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _isDarkMode = data['darkMode'] as bool? ?? false;
        _searchCache =
            (data['searchCache'] as List?)?.cast<String>() ?? [];
      }
    } catch (_) {}
  }

  Future<void> _savePrefs() async {
    try {
      final dir = await _getAppDir();
      final file = File('${dir.path}/prefs.json');
      await file.writeAsString(jsonEncode({
        'darkMode': _isDarkMode,
        'searchCache': _searchCache,
      }));
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    try {
      final dir = await _getAppDir();
      final file = File('${dir.path}/history.json');
      if (await file.exists()) {
        final list = jsonDecode(await file.readAsString()) as List;
        _listenHistory =
            list.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    try {
      final dir = await _getAppDir();
      final file = File('${dir.path}/history.json');
      await file.writeAsString(
          jsonEncode(_listenHistory.map((t) => t.toJson()).toList()));
    } catch (_) {}
  }

  Future<Directory> _getAppDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/owlmusic');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  void dispose() {
    youtubeService.dispose();
    playerService.dispose();
    downloader.dispose();
    super.dispose();
  }
}
