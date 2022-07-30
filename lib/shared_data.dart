import 'package:yt_songs/database.dart';
import 'package:yt_songs/theme.dart';
import 'database_song.dart';

class SharedData{
  static MyTheme myTheme = MyTheme();
  static double deviceWidth = 0;
  static double deviceHeight = 0;
  static late final DatabaseManager databaseManager;
  static List<DatabaseSong> downloadedSongs = [];
}