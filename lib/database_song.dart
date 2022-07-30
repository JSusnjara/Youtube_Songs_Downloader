class DatabaseSong{
  int? songId;
  String url; //just Yt video ID
  String title;
  String duration;
  downloadStatus status;


  DatabaseSong(this.songId, this.url, this.title, this.duration, this.status);

  DatabaseSong.withoutId(this.url, this.title, this.duration, this.status);

  Map<String, dynamic> toMap() {
    return {
      'song_id': songId,
      'url': url,
      'title': title,
      'duration': duration,
      'status': status.index
    };
  }
}

enum downloadStatus{
  success,
  failure,
  downloading,
  queued
}