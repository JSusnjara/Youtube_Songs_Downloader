import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yt_songs/song.dart';
import 'local_data.dart';
import 'package:http/http.dart';
import 'package:html_unescape/html_unescape.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {

  TextEditingController searchController = TextEditingController();
  ScrollController listScrollController = ScrollController();
  List<Song> songs = [];

  Future<void> search() async {
    songs = [];
    String baseUrl = "https://www.google.com/search?q=%22youtube.com%2Fwatch%3Fv%3D%22+";
    String urlString = baseUrl + Uri.encodeFull(searchController.text);
    urlString = urlString.replaceAll("%20", "+").replaceAll("&", "%26") + "&tbm=vid";
    var response = await get(Uri.parse(urlString));
    if(response.statusCode == 200){
      String htmlDocument = response.body;
      scrape(htmlDocument);
    }
  }

  void tidyScreen(){
    FocusManager.instance.primaryFocus?.unfocus();
    final position = listScrollController.position.minScrollExtent;
    listScrollController.jumpTo(position);
  }

  void scrape(String html){
    String str1 = "href=\"/url?q=https://www.youtube.com/watch%3Fv%3D";
    String str2 = "<div";
    bool linkFound = false;
    bool titleFound = false;
    String url = "";
    String title = "";
    String duration = "";

    for(int i = 10000; i < html.length - 20000; i++){


      if(!linkFound && html.substring(i, i + str1.length) == str1){
        linkFound = true;
        url = html.substring(i + str1.length, i + str1.length + 11);
      }

      if(linkFound && !titleFound && html.substring(i, i + str2.length) == str2){
        titleFound = true;
        while(html.substring(i, i + 1) != ">")
          i++;
        int titleStart = ++i;
        while(html.substring(i, i + 6) != "</div>")
          i++;
        int titleEnd = i;
        title = HtmlUnescape().convert(html.substring(titleStart, titleEnd));
      }
      
      if(linkFound && titleFound){
        linkFound = false;
        titleFound = false;
        for(int j = 0; j < 3; j++){
          while(html.substring(i, i + 5) != "<span")
            i++;
          i++;
        }
        while(html.substring(i, i + 1) != ">")
          i++;
        int durStart = ++i;
        while(html.substring(i, i + 1) != "<")
          i++;
        int durEnd = i;
        duration = html.substring(durStart, durEnd);
        setState(() {
          songs.add(Song(url, title, duration));
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {

    LocalData.deviceWidth = MediaQuery.of(context).size.width;
    LocalData.deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text("Search"),
      ),
      body: Column(
        children: [
          SizedBox(height: LocalData.deviceHeight * 0.02,),
          Row(
            children: [
              SizedBox(width: LocalData.deviceWidth * 0.05,),
              Expanded(
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value){
                    tidyScreen();
                    search();
                  },
                ),
              ),
              SizedBox(width: LocalData.deviceWidth * 0.025,),
              TextButton(onPressed: (){
                tidyScreen();
                search();
              },
                  child: Text("Search")),
              SizedBox(width: LocalData.deviceWidth * 0.05,),
            ],
          ),
          Expanded(
            child: ListView.builder(
              controller: listScrollController,
                itemCount: songs.length,
                itemBuilder: (context, position){
              return Card(
                margin: EdgeInsets.fromLTRB(LocalData.deviceWidth * 0.03, LocalData.deviceHeight * 0.01,
                    LocalData.deviceWidth * 0.03, 0),
                child: Padding(
                  padding: EdgeInsets.all(LocalData.deviceWidth * 0.03),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(songs[position].title, maxLines: 2, overflow: TextOverflow.ellipsis,)),
                      SizedBox(width: LocalData.deviceWidth * 0.03,),
                      Text(songs[position].duration),
                    ],
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
