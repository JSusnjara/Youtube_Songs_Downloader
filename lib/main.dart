import 'package:flutter/material.dart';
import 'package:yt_songs/database.dart';
import 'package:yt_songs/downloads_screen.dart';
import 'package:yt_songs/shared_data.dart';
import 'package:yt_songs/search_screen.dart';
import 'package:yt_songs/settings.dart';

void main() async {
  SharedData.databaseManager = DatabaseManager();
  await SharedData.databaseManager.initialize().then((value) => {
    runApp(MyApp())
  });
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  int navigationIndex = 0;
  List<Widget> pagesList = [SearchScreen(), DownloadsScreen(), Settings()];

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      theme: SharedData.myTheme.getThemeData(),
      home: Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.download), label: "Downloads"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
          ],
          currentIndex: navigationIndex,
          onTap: (int index){
            setState(() {
              navigationIndex = index;
            });
          },
        ),
        body: IndexedStack(
          index: navigationIndex,
          children: pagesList,
        ),
      ),
    );
  }
}