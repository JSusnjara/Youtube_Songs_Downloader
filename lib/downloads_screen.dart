import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'database_song.dart';
import 'shared_data.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  _DownloadsScreenState createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {

  List<DatabaseSong> songs = [];
  ScrollController listScrollController = ScrollController();


  @override
  void initState() {
    getSongs();
  }

  Future<void> getSongs() async{
    songs = await SharedData.databaseManager.getSongs();
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Downloads"),
      ),
      body: Column(
        children: [
          SizedBox(height: SharedData.deviceHeight * 0.02,),
          Expanded(
            child: ListView.builder(
                controller: listScrollController,
                itemCount: songs.length,
                itemBuilder: (context, position) {
                  return GestureDetector(
                    onTap: () {

                    },
                    child: Card(
                      margin: EdgeInsets.fromLTRB(SharedData.deviceWidth * 0.03,
                          SharedData.deviceHeight * 0.01,
                          SharedData.deviceWidth * 0.03, 0),
                      child: Padding(
                        padding: EdgeInsets.all(SharedData.deviceWidth * 0.03),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(songs[position].title, maxLines: 2,
                                  overflow: TextOverflow.ellipsis,)),
                            SizedBox(width: SharedData.deviceWidth * 0.03,),
                            Text(songs[position].duration),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
          )
        ],
      ),
    );
  }
}
