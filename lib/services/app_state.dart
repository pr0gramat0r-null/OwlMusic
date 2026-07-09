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
  bool _isSearching = false;
  List<Track> _listenHistory = [];
  List<String> _searchCache = [];
  bool _isDarkMode = true;
  SearchType _searchType = SearchType.music;
  final Map<String, double> _downloadProgress = {};
  final Map<String, String> _downloadStatus = {};
  Set<String> _downloadedIds = {};
  final Map<String, String> _downloadedPaths = {};
  final Set<String> _cancelledDownloads = {};

  AppState({
    required this.youtubeService,
    required this.playlistManager,
    required this.playerService,
    required this.downloader,
  }) {
    playerService.setOnStateChanged(_onPlayerStateChanged);
    playerService.setYouTubeService(youtubeService);
    downloader.setYouTubeService(youtubeService);
    downloader.setOnProgress(_onDownloadProgress);
  }

  List<Track> get searchResults => _searchResults;
  String? get searchError => _searchError;
  bool get isSearching => _isSearching;
  List<Track> get listenHistory => List.unmodifiable(_listenHistory);
  List<String> get searchCache => List.unmodifiable(_searchCache);
  bool get isDarkMode => _isDarkMode;
  SearchType get searchType => _searchType;
  Track? get currentTrack => playerService.currentTrack;
  bool get isPlayerLoading => playerService.isLoading;
  String? get playerError => playerService.error;

  double getDownloadProgress(String trackId) =>
      _downloadProgress[trackId] ?? 0;
  String getDownloadStatus(String trackId) =>
      _downloadStatus[trackId] ?? '';
  bool isTrackDownloaded(String trackId) => _downloadedIds.contains(trackId);
  String? getLocalPath(String trackId) => _downloadedPaths[trackId];

  void _onPlayerStateChanged() {
    notifyListeners();
  }

  void _onDownloadProgress(String trackId, double progress, String status) {
    if (_cancelledDownloads.contains(trackId)) return;
    _downloadProgress[trackId] = progress;
    _downloadStatus[trackId] = status;
    if (progress >= 1.0) {
      _downloadedIds.add(trackId);
    }
    notifyListeners();
  }

  void cancelDownload(Track track) {
    downloader.cancelDownload(track.id);
    _cancelledDownloads.add(track.id);
    _downloadProgress.remove(track.id);
    _downloadStatus.remove(track.id);
    _downloadedIds.remove(track.id);
    notifyListeners();
  }

  Future<void> init() async {
    await playlistManager.load();
    await _loadPrefs();
    await _loadHistory();
    await _loadDownloadedIds();
  }

  Future<void> search(String query) async {
    _searchError = null;
    _isSearching = true;
    notifyListeners();
    try {
      _searchResults =
          await youtubeService.search(query, type: _searchType);
      if (!_searchCache.contains(query)) {
        _searchCache.insert(0, query);
        if (_searchCache.length > 20) _searchCache.removeLast();
      }
      _savePrefs();
    } catch (e) {
      _searchError = 'Search failed: $e';
      _searchResults = [];
    }
    _isSearching = false;
    notifyListeners();
  }

  void setSearchType(SearchType type) {
    _searchType = type;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _searchError = null;
    notifyListeners();
  }

  void removeSearchSuggestion(String query) {
    _searchCache.remove(query);
    _savePrefs();
    notifyListeners();
  }

  Future<void> playTrack(Track track) async {
    final enriched = _enrich(track);
    await playerService.play(enriched);
    _addToHistory(enriched);
    notifyListeners();
  }

  Future<void> playPlaylist(List<Track> tracks, {int startIndex = 0}) async {
    final enriched = tracks.map(_enrich).toList();
    await playerService.setQueue(enriched, startIndex: startIndex);
    if (enriched.isNotEmpty && startIndex < enriched.length) {
      _addToHistory(enriched[startIndex]);
    }
    notifyListeners();
  }

  Track _enrich(Track track) {
    final path = _downloadedPaths[track.id];
    if (path == null) return track;
    return track.copyWith(downloaded: true, localPath: path);
  }

  void _addToHistory(Track track) {
    _listenHistory.removeWhere((t) => t.id == track.id);
    _listenHistory.insert(0, track);
    if (_listenHistory.length > 50) _listenHistory.removeLast();
    _saveHistory();
  }

  void clearHistory() {
    _listenHistory.clear();
    _saveHistory();
    notifyListeners();
  }

  Future<void> downloadTrack(Track track) async {
    _downloadProgress[track.id] = 0;
    _downloadStatus[track.id] = 'Starting...';
    notifyListeners();

    final path = await downloader.downloadTrack(track);
    if (path != null) {
      _downloadedIds.add(track.id);
      _downloadedPaths[track.id] = path;
      _saveDownloadedIds();
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
        _isDarkMode = data['darkMode'] as bool? ?? true;
        _searchCache =
            (data['searchCache'] as List?)?.cast<String>() ?? [];
        final typeIdx = data['searchType'] as int? ?? 1;
        _searchType = SearchType.values[typeIdx.clamp(0, SearchType.values.length - 1).toInt()];
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
        'searchType': _searchType.index,
      }));
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    try {
      final dir = await _getAppDir();
      final file = File('${dir.path}/history.json');
      if (await file.exists()) {
        final list = jsonDecode(await file.readAsString()) as List;
        _listenHistory = list
            .map((e) => Track.fromJson(e as Map<String, dynamic>))
            .toList();
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

  Future<void> _loadDownloadedIds() async {
    try {
      final dir = await _getAppDir();
      final file = File('${dir.path}/downloaded.json');
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        if (data is Map) {
          data.forEach((k, v) {
            final id = k.toString();
            _downloadedIds.add(id);
            if (v != null) _downloadedPaths[id] = v.toString();
          });
        } else if (data is List) {
          _downloadedIds = data.cast<String>().toSet();
        }
      }
    } catch (_) {}
  }

  Future<void> _saveDownloadedIds() async {
    try {
      final dir = await _getAppDir();
      final file = File('${dir.path}/downloaded.json');
      await file.writeAsString(jsonEncode(
        _downloadedPaths.map((k, v) => MapEntry(k, v)),
      ));
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
