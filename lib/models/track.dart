class Track {
  final String id;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final String url;
  final Duration? duration;
  bool downloaded;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    this.thumbnailUrl = '',
    required this.url,
    this.duration,
    this.downloaded = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'thumbnailUrl': thumbnailUrl,
        'url': url,
        'duration': duration?.inSeconds,
        'downloaded': downloaded,
      };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
        url: json['url'] as String,
        duration: json['duration'] != null
            ? Duration(seconds: json['duration'] as int)
            : null,
        downloaded: json['downloaded'] as bool? ?? false,
      );

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? thumbnailUrl,
    String? url,
    Duration? duration,
    bool? downloaded,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      url: url ?? this.url,
      duration: duration ?? this.duration,
      downloaded: downloaded ?? this.downloaded,
    );
  }

  String get durationText {
    if (duration == null) return '--:--';
    final m = duration!.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration!.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
