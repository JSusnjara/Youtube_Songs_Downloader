import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:yt_songs/database_song.dart';

class DatabaseManager{

  late final database;

  Future<void> initialize() async{
    WidgetsFlutterBinding.ensureInitialized();
    database = openDatabase(
        join(await getDatabasesPath(), 'downloaded_songs.db'),
        onCreate: (db, version) {
    return db.execute(
    'CREATE TABLE downloaded_songs (song_id INTEGER PRIMARY KEY, url TEXT, title TEXT, duration TEXT, status INTEGER)',
    );
    },
    version: 1,
    );
  }


  Future<void> insertSong(DatabaseSong song) async {
    final db = await database;
    var res = await db.insert(
      'downloaded_songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    //print("INSERT: " + res.toString());
    //res is the id of inserted row
  }

  Future<List<DatabaseSong>> getSongs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('downloaded_songs');
    return List.generate(maps.length, (i) {
      return DatabaseSong(maps[i]['song_id'], maps[i]['url'], maps[i]['title'], maps[i]['duration'], downloadStatus.values[maps[i]['status']]);
    });
  }

  Future<void> updateSong(DatabaseSong song) async {
    final db = await database;
    await db.update(
      'downloaded_songs',
      song.toMap(),
      where: 'song_id = ?',
      whereArgs: [song.songId],
    );
  }

  Future<void> deleteSong(int songId) async {
    final db = await database;
    await db.delete(
      'downloaded_songs',
      where: 'id = ?',
      whereArgs: [songId],
    );
  }



}