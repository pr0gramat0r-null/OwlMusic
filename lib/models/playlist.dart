import 'track.dart';

class Playlist {
  final String id;
  final String name;
  final List<Track> tracks;

  Playlist({
    required this.id,
    required this.name,
    List<Track>? tracks,
  }) : tracks = tracks ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tracks': tracks.map((t) => t.toJson()).toList(),
      };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'] as String,
        name: json['name'] as String,
        tracks: (json['tracks'] as List?)
                ?.map((t) => Track.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Playlist copyWith({
    String? id,
    String? name,
    List<Track>? tracks,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      tracks: tracks ?? this.tracks,
    );
  }

  bool containsTrack(String trackId) => tracks.any((t) => t.id == trackId);

  Playlist addTrack(Track track) {
    if (containsTrack(track.id)) return this;
    return copyWith(tracks: [...tracks, track]);
  }

  Playlist removeTrack(String trackId) {
    return copyWith(tracks: tracks.where((t) => t.id != trackId).toList());
  }

  int get trackCount => tracks.length;

  Duration get totalDuration {
    final secs = tracks.fold<int>(
        0, (sum, t) => sum + (t.duration?.inSeconds ?? 0));
    return Duration(seconds: secs);
  }

  String get totalDurationText {
    final d = totalDuration;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    if (h > 0) {
      return '$h:$m';
    }
    return '${d.inMinutes} min';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
