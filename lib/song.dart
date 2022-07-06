class Song{
  String url;
  String title;
  String duration;
  bool songDownloaded = false;
  String? downloadTaskId;

  Song(this.url, this.title, this.duration);
}