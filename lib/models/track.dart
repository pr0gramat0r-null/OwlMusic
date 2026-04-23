class Track {
  final String id;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final String url;
  final Duration? duration;
  final bool downloaded;
  final String? localPath;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    this.thumbnailUrl = '',
    required this.url,
    this.duration,
    this.downloaded = false,
    this.localPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'thumbnailUrl': thumbnailUrl,
        'url': url,
        'duration': duration?.inSeconds,
        'downloaded': downloaded,
        'localPath': localPath,
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
        localPath: json['localPath'] as String?,
      );

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? thumbnailUrl,
    String? url,
    Duration? duration,
    bool? downloaded,
    String? localPath,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      url: url ?? this.url,
      duration: duration ?? this.duration,
      downloaded: downloaded ?? this.downloaded,
      localPath: localPath ?? this.localPath,
    );
  }

  String get durationText {
    if (duration == null) return '--:--';
    final m = duration!.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration!.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get isMusicLength {
    if (duration == null) return true;
    final secs = duration!.inSeconds;
    return secs >= 30 && secs <= 600;
  }

  double get musicRelevanceScore {
    double score = 0.0;
    final lowerTitle = title.toLowerCase();
    final lowerArtist = artist.toLowerCase();

    if (lowerTitle.contains('official')) score += 3;
    if (lowerTitle.contains('lyric')) score += 2;
    if (lowerTitle.contains('audio')) score += 2;
    if (lowerTitle.contains('music video')) score += 2;
    if (lowerTitle.contains('mv')) score += 1;
    if (lowerTitle.contains('cover')) score += 1;
    if (lowerTitle.contains('remix')) score += 1;
    if (lowerTitle.contains('feat') || lowerTitle.contains('ft.')) score += 1;
    if (lowerArtist.contains('vevo')) score += 3;
    if (lowerArtist.contains('official')) score += 2;
    if (lowerArtist.contains('music')) score += 1;
    if (lowerArtist.contains('records')) score += 1;
    if (lowerTitle.contains('topic') || lowerArtist.contains('topic')) {
      score += 2;
    }
    if (isMusicLength) score += 2;

    if (lowerTitle.contains('trailer') ||
        lowerTitle.contains('tutorial') ||
        lowerTitle.contains('review') ||
        lowerTitle.contains('vlog') ||
        lowerTitle.contains('reaction')) {
      score -= 5;
    }

    return score;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
